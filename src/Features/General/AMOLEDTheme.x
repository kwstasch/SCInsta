#import <UIKit/UIKit.h>
#import <substrate.h>
#import <dlfcn.h>
#import "../../InstagramHeaders.h"
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// PURE AMOLED THEME (#000000)
//
// Part 1 — view tinting. Instagram builds a lot of containers in plain UIKit,
//          so we paint the backgrounds of the usual suspects.
//
// Part 2 — IGDS palette override. Everything else (list rows, the DM composer,
//          the notes surface, the thread backdrop) does NOT get its color from
//          a view property: it asks FBSharedFramework for one of 253 exported
//          C functions (IGDSColorBackgroundSecondary(), ...). Painting views
//          can never reach those, which is why those surfaces stayed #262626.
//          We hook just the surface tokens, never text/icon/border tokens, so
//          contrast is preserved.
// ─────────────────────────────────────────────────────────────────────────────

// Kept in sync on the main thread (traitCollection is only safe there).
static BOOL SCIAmoledDark = YES;

static inline BOOL isAMOLEDActive(UIView *view) {
    if (!view || !view.window) return NO;
    if (![SCIUtils getBoolPref:@"amoled_mode"]) return NO;
    return (view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
}

static inline BOOL SCIAmoledActive(void) {
    return [SCIUtils getBoolPref:@"amoled_mode"] && SCIAmoledDark;
}

static inline BOOL shouldSkipViewController(UIViewController *vc) {
    if (!vc) return NO;

    // Exclude DM chat thread controllers
    if ([vc isKindOfClass:%c(IGDirectThreadViewController)]) return YES;

    // Exclude modal overlays and popups (Notes viewer, popovers, transparent sheets)
    if (vc.modalPresentationStyle == UIModalPresentationOverFullScreen ||
        vc.modalPresentationStyle == UIModalPresentationOverCurrentContext ||
        vc.modalPresentationStyle == UIModalPresentationCustom) {
        return YES;
    }

    NSString *clsName = NSStringFromClass([vc class]);
    if ([clsName containsString:@"Notes"] || [clsName containsString:@"Overlay"] || [clsName containsString:@"Prompt"]) {
        return YES;
    }

    // If view is intentionally clear/transparent, keep it transparent
    if ([vc isViewLoaded]) {
        UIColor *bg = vc.view.backgroundColor;
        if (!bg || [bg isEqual:[UIColor clearColor]]) return YES;
        CGFloat a = 1.0;
        [bg getRed:nil green:nil blue:nil alpha:&a];
        if (a < 0.5) return YES;
    }

    return NO;
}

%hook UIViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;

    // Refresh the dark-mode cache on the main thread for the palette hooks.
    SCIAmoledDark = (self.traitCollection.userInterfaceStyle != UIUserInterfaceStyleLight);

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
    %orig;
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
    %orig;
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

// ═════════════════════════════════════════════════════════════════════════════
// PART 2 — IGDS palette override
//
// Every symbol below lives in
//   Instagram.app/Frameworks/FBSharedFramework.framework/FBSharedFramework
// and is exported. They take no arguments (verified in the v454 binary) and
// return a UIColor *, so MSHookFunction is enough.
//
// If a surface ever loses contrast (e.g. a message bubble that used to be grey
// becomes invisible), just comment out that single SCI_AMOLED_COLOR_HOOK line
// and rebuild — nothing else depends on it.
// ═════════════════════════════════════════════════════════════════════════════

#define SCI_AMOLED_COLOR_HOOK(token)                                            \
    static UIColor *(*sci_orig_##token)(void) = NULL;                           \
    static UIColor *sci_hook_##token(void) {                                    \
        if (SCIAmoledActive()) return [UIColor blackColor];                     \
        return sci_orig_##token ? sci_orig_##token() : nil;                     \
    }                                                                           \
    static void sci_install_##token(void) {                                     \
        void *sym = dlsym(RTLD_DEFAULT, #token);                                \
        if (!sym) {                                                             \
            NSLog(@"[SCInsta] AMOLED: missing symbol %s", #token);              \
            return;                                                             \
        }                                                                       \
        MSHookFunction(sym, (void *)sci_hook_##token,                           \
                       (void **)&sci_orig_##token);                             \
        NSLog(@"[SCInsta] AMOLED: hooked %s", #token);                          \
    }

// ── Direct: the surfaces you reported ───────────────────────────────────────
SCI_AMOLED_COLOR_HOOK(IGDSColorDirectGreyComposerBackgroundColor)   // composer / input bar
SCI_AMOLED_COLOR_HOOK(IGDSColorInbox2NotesBackgroundColor)          // notes surface in the inbox

// ── Base / secondary / elevated surfaces (rows, thread backdrop, sheets) ────
// Message bubbles are NOT drawn from these tokens: they use the per-thread
// IGDirectThreadTheme palette, so recoloring these is safe for chat.
SCI_AMOLED_COLOR_HOOK(IGDSColorBackgroundPrimary)
SCI_AMOLED_COLOR_HOOK(IGDSColorBackgroundSecondary)
SCI_AMOLED_COLOR_HOOK(IGDSColorBackgroundSecondaryStrong)
SCI_AMOLED_COLOR_HOOK(IGDSColorBackgroundSecondaryStronger)
SCI_AMOLED_COLOR_HOOK(IGDSColorBackgroundSecondary_LEGACY)
SCI_AMOLED_COLOR_HOOK(IGDSColorBackgroundElevated)
SCI_AMOLED_COLOR_HOOK(IGDSColorBackgroundElevatedStrong)

%ctor {
    @autoreleasepool {
        // Make sure the framework is mapped before we resolve symbols in it.
        NSString *fwPath = [[[NSBundle mainBundle] privateFrameworksPath]
                            stringByAppendingPathComponent:@"FBSharedFramework.framework/FBSharedFramework"];
        if (fwPath.length) {
            dlopen(fwPath.fileSystemRepresentation, RTLD_LAZY);
        }

        sci_install_IGDSColorDirectGreyComposerBackgroundColor();
        sci_install_IGDSColorInbox2NotesBackgroundColor();

        sci_install_IGDSColorBackgroundPrimary();
        sci_install_IGDSColorBackgroundSecondary();
        sci_install_IGDSColorBackgroundSecondaryStrong();
        sci_install_IGDSColorBackgroundSecondaryStronger();
        sci_install_IGDSColorBackgroundSecondary_LEGACY();
        sci_install_IGDSColorBackgroundElevated();
        sci_install_IGDSColorBackgroundElevatedStrong();
    }
}
