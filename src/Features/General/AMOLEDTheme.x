#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <string.h>
#import "../../InstagramHeaders.h"
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// SAFE PURE AMOLED THEME (#000000)
// UI container tinting for OLED screens in Dark Mode (100% crash-free)
// ─────────────────────────────────────────────────────────────────────────────

// Set while a DM conversation is on screen, so the guard is already active
// before the message list is laid out.
static BOOL gSCIDMThreadVisible = NO;

// A conversation is hosted by several controllers that are NOT subclasses of
// IGDirectThreadViewController: half-sheet navigation controllers, bottom-sheet
// presenters, drawing/media controllers, etc. Matching a single class missed
// them, and tinting their full-screen view blacked out the whole chat.
// Match the whole family by name instead.
static inline BOOL sci_isDirectThreadClass(Class cls) {
    for (Class c = cls; c != Nil; c = class_getSuperclass(c)) {
        const char *name = class_getName(c);
        if (name && strstr(name, "DirectThread") != NULL) return YES;
    }
    return NO;
}

static inline BOOL sci_isDirectThreadController(UIViewController *vc) {
    if (!vc) return NO;
    return sci_isDirectThreadClass(object_getClass(vc));
}

static inline BOOL isAlreadyBlack(UIColor *color) {
    if (!color) return NO;
    return [color isEqual:[UIColor blackColor]];
}

static inline BOOL isAMOLEDActive(UIView *view) {
    if (gSCIDMThreadVisible) return NO;
    if (!view || !view.window) return NO;
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return NO;
    return (view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
}

static inline BOOL shouldSkipViewController(UIViewController *vc) {
    if (gSCIDMThreadVisible) return YES;
    if (!vc) return NO;

    // Exclude the whole DM conversation family (message bubbles & chat themes),
    // walking the containment chain because the thread hosts its list, composer
    // and navigation inside child controllers.
    for (UIViewController *v = vc; v != nil; v = v.parentViewController) {
        if (sci_isDirectThreadController(v)) return YES;
    }

    // Only inspect modal presentations (Notes viewer, popovers, custom transparent sheets)
    if (vc.presentingViewController != nil) {
        if (vc.modalPresentationStyle == UIModalPresentationOverFullScreen ||
            vc.modalPresentationStyle == UIModalPresentationOverCurrentContext ||
            vc.modalPresentationStyle == UIModalPresentationCustom) {
            return YES;
        }

        NSString *clsName = NSStringFromClass([vc class]);
        if ([clsName containsString:@"Notes"] || [clsName containsString:@"Overlay"] || [clsName containsString:@"Prompt"]) {
            return YES;
        }

        if ([vc isViewLoaded]) {
            UIColor *bg = vc.view.backgroundColor;
            if (!bg || [bg isEqual:[UIColor clearColor]]) return YES;
            CGFloat a = 1.0;
            [bg getRed:nil green:nil blue:nil alpha:&a];
            if (a < 0.5) return YES;
        }
    }

    return NO;
}

// ── DM thread guard ─────────────────────────────────────────────────────────
// Raised before the conversation appears and lowered after it is gone.
%hook IGDirectThreadViewController

- (void)viewWillAppear:(BOOL)animated {
    gSCIDMThreadVisible = YES;
    %orig;
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    gSCIDMThreadVisible = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    gSCIDMThreadVisible = NO;
}

%end

%hook UIViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (gSCIDMThreadVisible) return;
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return;
    if (self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark) return;
    if (![self isViewLoaded]) return;

    if (shouldSkipViewController(self)) return;
    if (isAlreadyBlack(self.view.backgroundColor)) return;

    self.view.backgroundColor = [UIColor blackColor];
}

%end

%hook UITableView

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC)) return;
        if (isAlreadyBlack(self.backgroundColor)) return;

        self.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC) || isAlreadyBlack(color)) {
            %orig(color);
            return;
        }
        %orig([UIColor blackColor]);
        return;
    }
    %orig(color);
}

%end

%hook UICollectionView

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC)) return;
        if (isAlreadyBlack(self.backgroundColor)) return;

        self.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC) || isAlreadyBlack(color)) {
            %orig(color);
            return;
        }
        %orig([UIColor blackColor]);
        return;
    }
    %orig(color);
}

%end

%hook UITableViewCell

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC)) return;

        if (!isAlreadyBlack(self.backgroundColor)) self.backgroundColor = [UIColor blackColor];
        if (!isAlreadyBlack(self.contentView.backgroundColor)) self.contentView.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC) || isAlreadyBlack(color)) {
            %orig(color);
            return;
        }
        %orig([UIColor blackColor]);
        return;
    }
    %orig(color);
}

- (void)layoutSubviews {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC)) return;

        if (!isAlreadyBlack(self.backgroundColor)) self.backgroundColor = [UIColor blackColor];
        if (!isAlreadyBlack(self.contentView.backgroundColor)) self.contentView.backgroundColor = [UIColor blackColor];
    }
}

%end

%hook UICollectionViewCell

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC)) return;

        if (!isAlreadyBlack(self.backgroundColor)) self.backgroundColor = [UIColor blackColor];
        if (!isAlreadyBlack(self.contentView.backgroundColor)) self.contentView.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC) || isAlreadyBlack(color)) {
            %orig(color);
            return;
        }
        %orig([UIColor blackColor]);
        return;
    }
    %orig(color);
}

- (void)layoutSubviews {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (!parentVC || shouldSkipViewController(parentVC)) return;

        if (!isAlreadyBlack(self.backgroundColor)) self.backgroundColor = [UIColor blackColor];
        if (!isAlreadyBlack(self.contentView.backgroundColor)) self.contentView.backgroundColor = [UIColor blackColor];
    }
}

%end

%hook UINavigationBar

- (void)didMoveToWindow {
    %orig;
    if (!isAMOLEDActive(self)) return;

    // Bars have no controller of their own; ask the hierarchy instead.
    id parentVC = [SCIUtils nearestViewControllerForView:self];
    if (parentVC && shouldSkipViewController(parentVC)) return;
    if (isAlreadyBlack(self.backgroundColor)) return;

    self.barTintColor = [UIColor blackColor];
    self.backgroundColor = [UIColor blackColor];
}

%end

%hook UITabBar

- (void)didMoveToWindow {
    %orig;
    if (!isAMOLEDActive(self)) return;

    id parentVC = [SCIUtils nearestViewControllerForView:self];
    if (parentVC && shouldSkipViewController(parentVC)) return;
    if (isAlreadyBlack(self.backgroundColor)) return;

    self.barTintColor = [UIColor blackColor];
    self.backgroundColor = [UIColor blackColor];
}

%end
