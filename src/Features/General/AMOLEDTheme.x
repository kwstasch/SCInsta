#import <UIKit/UIKit.h>
#import "../../InstagramHeaders.h"
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// SAFE PURE AMOLED THEME (#000000)
// UI container tinting for OLED screens in Dark Mode (100% crash-free)
// ─────────────────────────────────────────────────────────────────────────────

static inline BOOL isAMOLEDActive(UIView *view) {
    if (!view || !view.window) return NO;
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return NO;
    return (view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
}

static inline BOOL shouldSkipViewController(UIViewController *vc) {
    if (!vc) return NO;

    // Exclude DM chat thread controllers (message bubbles & chat themes)
    if ([vc isKindOfClass:%c(IGDirectThreadViewController)]) return YES;

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

%hook UIViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return;
    if (self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark) return;
    if (![self isViewLoaded]) return;

    if (shouldSkipViewController(self)) return;

    self.view.backgroundColor = [UIColor blackColor];
}

%end

%hook UITableView

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && shouldSkipViewController(parentVC)) return;

        self.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && shouldSkipViewController(parentVC)) {
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
        if (parentVC && shouldSkipViewController(parentVC)) return;

        self.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && shouldSkipViewController(parentVC)) {
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
        if (parentVC && shouldSkipViewController(parentVC)) return;

        self.backgroundColor = [UIColor blackColor];
        self.contentView.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && shouldSkipViewController(parentVC)) {
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
        if (parentVC && shouldSkipViewController(parentVC)) return;

        self.backgroundColor = [UIColor blackColor];
        self.contentView.backgroundColor = [UIColor blackColor];
    }
}

%end

%hook UICollectionViewCell

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && shouldSkipViewController(parentVC)) return;

        self.backgroundColor = [UIColor blackColor];
        self.contentView.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && shouldSkipViewController(parentVC)) {
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
        if (parentVC && shouldSkipViewController(parentVC)) return;

        self.backgroundColor = [UIColor blackColor];
        self.contentView.backgroundColor = [UIColor blackColor];
    }
}

%end

%hook UINavigationBar

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        self.barTintColor = [UIColor blackColor];
        self.backgroundColor = [UIColor blackColor];
    }
}

%end

%hook UITabBar

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        self.barTintColor = [UIColor blackColor];
        self.backgroundColor = [UIColor blackColor];
    }
}

%end
