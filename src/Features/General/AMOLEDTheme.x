#import <UIKit/UIKit.h>
#import <substrate.h>
#import <dlfcn.h>
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// PURE AMOLED / PITCH BLACK THEME (Piko style)
// Converts Instagram's dark grey backgrounds (#121212 / #1C1C1E) into pure #000000
// ─────────────────────────────────────────────────────────────────────────────

%hook UIColor

+ (UIColor *)systemBackgroundColor {
    if ([SCIUtils getBoolPref:@"amoled_mode"] || [SCIUtils getBoolPref:@"amoled_theme"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : [UIColor whiteColor];
        }];
    }
    return %orig;
}

+ (UIColor *)secondarySystemBackgroundColor {
    if ([SCIUtils getBoolPref:@"amoled_mode"] || [SCIUtils getBoolPref:@"amoled_theme"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : [UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0];
        }];
    }
    return %orig;
}

+ (UIColor *)systemGroupedBackgroundColor {
    if ([SCIUtils getBoolPref:@"amoled_mode"] || [SCIUtils getBoolPref:@"amoled_theme"]) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor blackColor]
                : [UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1.0];
        }];
    }
    return %orig;
}

%end

// C function hooks inside %group so compile time does not require static extern declarations
%group IGDSColorFunctionsGroup

%hookf(UIColor *, _IGDSColorBackgroundPrimary, id traitCollection) {
    if ([SCIUtils getBoolPref:@"amoled_mode"] || [SCIUtils getBoolPref:@"amoled_theme"]) {
        return [UIColor blackColor];
    }
    return %orig(traitCollection);
}

%hookf(UIColor *, _IGDSColorBackgroundSecondary, id traitCollection) {
    if ([SCIUtils getBoolPref:@"amoled_mode"] || [SCIUtils getBoolPref:@"amoled_theme"]) {
        return [UIColor blackColor];
    }
    return %orig(traitCollection);
}

%hookf(UIColor *, _IGDSColorBackgroundElevated, id traitCollection) {
    if ([SCIUtils getBoolPref:@"amoled_mode"] || [SCIUtils getBoolPref:@"amoled_theme"]) {
        return [UIColor blackColor];
    }
    return %orig(traitCollection);
}

%end

%ctor {
    %init;

    void *symPrimary = MSFindSymbol(NULL, "_IGDSColorBackgroundPrimary") ?: MSFindSymbol(NULL, "__IGDSColorBackgroundPrimary") ?: dlsym(RTLD_DEFAULT, "IGDSColorBackgroundPrimary");
    void *symSecondary = MSFindSymbol(NULL, "_IGDSColorBackgroundSecondary") ?: MSFindSymbol(NULL, "__IGDSColorBackgroundSecondary") ?: dlsym(RTLD_DEFAULT, "IGDSColorBackgroundSecondary");
    void *symElevated = MSFindSymbol(NULL, "_IGDSColorBackgroundElevated") ?: MSFindSymbol(NULL, "__IGDSColorBackgroundElevated") ?: dlsym(RTLD_DEFAULT, "IGDSColorBackgroundElevated");

    if (symPrimary && symSecondary && symElevated) {
        %init(IGDSColorFunctionsGroup,
              _IGDSColorBackgroundPrimary = symPrimary,
              _IGDSColorBackgroundSecondary = symSecondary,
              _IGDSColorBackgroundElevated = symElevated);
    }
}
