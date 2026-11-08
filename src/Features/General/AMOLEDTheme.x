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
static inline BOOL sci_classNameContains(Class cls, const char *needle) {
    for (Class c = cls; c != Nil; c = class_getSuperclass(c)) {
        const char *name = class_getName(c);
        if (name && strstr(name, needle) != NULL) return YES;
    }
    return NO;
}

static inline BOOL sci_isDirectThreadClass(Class cls) {
    return sci_classNameContains(cls, "DirectThread");
}

static inline BOOL sci_isDirectThreadController(UIViewController *vc) {
    if (!vc) return NO;
    return sci_isDirectThreadClass(object_getClass(vc));
}

// Notes are drawn as translucent overlays (immersive viewer, consumption card
// collections, composer container) and the note itself lives in cells. Theming
// them painted the note black too, leaving just the keyboard visible.
static inline BOOL sci_isNotesController(UIViewController *vc) {
    for (UIViewController *v = vc; v != nil; v = v.parentViewController) {
        if (sci_classNameContains(object_getClass(v), "Notes")) return YES;
    }
    return NO;
}

// The controller that was actually presented. A child VC has no
// presentingViewController of its own, which is why the modal checks used to
// miss transparent viewers hosted inside a navigation/container controller.
static inline UIViewController *sci_presentationAnchor(UIViewController *vc) {
    UIViewController *top = vc;
    while (top.parentViewController != nil) top = top.parentViewController;
    if (top.presentingViewController != nil) return top;
    return nil;
}

// The window whose root controller is this controller.
static inline UIWindow *sci_windowRooting(UIViewController *vc) {
    UIViewController *top = vc;
    while (top.parentViewController != nil) top = top.parentViewController;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.rootViewController == top) return window;
    }
    return nil;
}

// Debug tools (FLEX and friends) live in their own window on top of the app and
// are translucent by design. Painting their root view black makes the whole
// window opaque, so the app behind it disappears.
static inline BOOL sci_isToolWindow(UIWindow *window) {
    if (!window) return NO;
    UIViewController *root = window.rootViewController;
    if (!root) return NO;
    if (sci_classNameContains(object_getClass(root), "FLEX")) return YES;
    if ([root isKindOfClass:[UINavigationController class]]) {
        UIViewController *top = ((UINavigationController *)root).topViewController;
        if (top != nil && sci_classNameContains(object_getClass(top), "FLEX")) return YES;
    }
    return NO;
}

static inline BOOL isAlreadyBlack(UIColor *color) {
    if (!color) return NO;
    return [color isEqual:[UIColor blackColor]];
}

static inline BOOL isAMOLEDActive(UIView *view) {
    if (gSCIDMThreadVisible) return NO;
    if (!view || !view.window) return NO;
    if (sci_isToolWindow(view.window)) return NO;
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return NO;
    return (view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
}

static inline BOOL shouldSkipViewController(UIViewController *vc) {
    if (gSCIDMThreadVisible) return YES;
    if (!vc) return NO;

    // Translucent debug windows (FLEX) must stay translucent.
    UIWindow *hostWindow = [vc isViewLoaded] ? vc.view.window : nil;
    if (hostWindow == nil) hostWindow = sci_windowRooting(vc);
    if (sci_isToolWindow(hostWindow)) return YES;

    // Exclude the whole DM conversation family (message bubbles & chat themes),
    // walking the containment chain because the thread hosts its list, composer
    // and navigation inside child controllers.
    for (UIViewController *v = vc; v != nil; v = v.parentViewController) {
        if (sci_isDirectThreadController(v)) return YES;
    }

    // Notes (immersive viewer, details, composer) are translucent overlays over
    // the inbox. Skip them no matter how they were presented.
    if (sci_isNotesController(vc)) return YES;

    // Only inspect modal presentations (popovers, custom transparent sheets).
    // Use the presented root: the visible content is usually a child of it.
    UIViewController *anchor = sci_presentationAnchor(vc);
    if (anchor) {
        if (anchor.modalPresentationStyle == UIModalPresentationOverFullScreen ||
            anchor.modalPresentationStyle == UIModalPresentationOverCurrentContext ||
            anchor.modalPresentationStyle == UIModalPresentationCustom) {
            return YES;
        }

        // Containers often report a nil background; inspect the visible child.
        UIViewController *probe = anchor;
        if ([probe isKindOfClass:[UINavigationController class]] &&
            ((UINavigationController *)probe).topViewController != nil) {
            probe = ((UINavigationController *)probe).topViewController;
        } else if ([probe isKindOfClass:[UITabBarController class]] &&
                   ((UITabBarController *)probe).selectedViewController != nil) {
            probe = ((UITabBarController *)probe).selectedViewController;
        }

        NSString *clsName = NSStringFromClass([probe class]);
        if ([clsName containsString:@"Overlay"] || [clsName containsString:@"Prompt"]) {
            return YES;
        }

        if ([probe isViewLoaded]) {
            UIColor *bg = probe.view.backgroundColor;
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

%hook UISearchBar

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

// The grey pill of a search bar is a UISearchTextField. It is not a cell, so
// none of the cell hooks reach it, and Instagram sets its colour before it is
// in a window - where isAMOLEDActive() is still NO. Hook both the setter and
// the layout pass, but only for that one class so ordinary text fields keep
// whatever colour their owner wanted.
static inline BOOL sci_isSearchTextField(UITextField *field) {
    Class searchFieldClass = NSClassFromString(@"UISearchTextField");
    if (!searchFieldClass || !field) return NO;
    return [field isKindOfClass:searchFieldClass];
}

%hook UITextField

- (void)setBackgroundColor:(UIColor *)color {
    if (!sci_isSearchTextField(self) || !isAMOLEDActive(self)) {
        %orig(color);
        return;
    }

    id parentVC = [SCIUtils nearestViewControllerForView:self];
    if (!parentVC || shouldSkipViewController(parentVC) || isAlreadyBlack(color)) {
        %orig(color);
        return;
    }
    %orig([UIColor blackColor]);
}

- (void)layoutSubviews {
    %orig;
    if (!sci_isSearchTextField(self) || !isAMOLEDActive(self)) return;

    id parentVC = [SCIUtils nearestViewControllerForView:self];
    if (!parentVC || shouldSkipViewController(parentVC)) return;
    if (isAlreadyBlack(self.backgroundColor)) return;

    self.backgroundColor = [UIColor blackColor];
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
