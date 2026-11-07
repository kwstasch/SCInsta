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

%hook UIViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return;
    if (self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark) return;
    if (![self isViewLoaded]) return;

    // Do not interfere with DM chat thread controllers (they use custom chat theme engines)
    if ([self isKindOfClass:%c(IGDirectThreadViewController)]) return;

    self.view.backgroundColor = [UIColor blackColor];
}

%end

%hook UITableView

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        self.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        %orig([UIColor blackColor]);
        return;
    }
    %orig;
}

%end

%hook UICollectionView

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && [parentVC isKindOfClass:%c(IGDirectThreadViewController)]) return;

        self.backgroundColor = [UIColor blackColor];
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (isAMOLEDActive(self)) {
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && [parentVC isKindOfClass:%c(IGDirectThreadViewController)]) {
            %orig(color);
            return;
        }
        %orig([UIColor blackColor]);
        return;
    }
    %orig;
}

%end

%hook UITableViewCell

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        self.backgroundColor = [UIColor blackColor];
        self.contentView.backgroundColor = [UIColor blackColor];
    }
}

%end

%hook UICollectionViewCell

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        // Exclude message cells inside chat threads
        id parentVC = [SCIUtils nearestViewControllerForView:self];
        if (parentVC && [parentVC isKindOfClass:%c(IGDirectThreadViewController)]) return;

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
