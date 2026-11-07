#import <UIKit/UIKit.h>
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// PURE AMOLED / PITCH BLACK THEME (Piko style)
// Converts Instagram's dark grey backgrounds (#121212 / #1C1C1E) into pure #000000
// ─────────────────────────────────────────────────────────────────────────────

%hook UIColor

+ (UIColor *)systemBackgroundColor {
    if ([SCIUtils getBoolPref:@"amoled_mode"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : [UIColor whiteColor];
        }];
    }
    return %orig;
}

+ (UIColor *)secondarySystemBackgroundColor {
    if ([SCIUtils getBoolPref:@"amoled_mode"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : [UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0];
        }];
    }
    return %orig;
}

+ (UIColor *)systemGroupedBackgroundColor {
    if ([SCIUtils getBoolPref:@"amoled_mode"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : [UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0];
        }];
    }
    return %orig;
}

%end

// Hook Instagram Design System (IGDS) global color functions
%hookf(UIColor *, _IGDSColorBackgroundPrimary) {
    if ([SCIUtils getBoolPref:@"amoled_mode"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : [UIColor whiteColor];
        }];
    }
    return %orig;
}

%hookf(UIColor *, _IGDSColorBackgroundSecondary) {
    if ([SCIUtils getBoolPref:@"amoled_mode"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : %orig;
        }];
    }
    return %orig;
}

%hookf(UIColor *, _IGDSColorBackgroundElevated) {
    if ([SCIUtils getBoolPref:@"amoled_mode"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor colorWithWhite:0.04 alpha:1.0]
                : %orig;
        }];
    }
    return %orig;
}
