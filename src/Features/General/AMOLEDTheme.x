#import <UIKit/UIKit.h>
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// SAFE PURE AMOLED THEME (#000000)
// UI container tinting for OLED screens in Dark Mode (100% crash-free)
// ─────────────────────────────────────────────────────────────────────────────

static inline BOOL isAMOLEDActive(UIView *view) {
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return NO;
    return (view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
}

%hook UIViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if ([SCIUtils getBoolPref:@"amoled_mode"] && self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        self.view.backgroundColor = [UIColor blackColor];
    }
}

%end

%hook UITableView

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        self.backgroundColor = [UIColor blackColor];
        self.backgroundView = nil;
    }
}

%end

%hook UICollectionView

- (void)didMoveToWindow {
    %orig;
    if (isAMOLEDActive(self)) {
        self.backgroundColor = [UIColor blackColor];
        self.backgroundView = nil;
    }
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
