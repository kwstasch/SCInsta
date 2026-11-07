@interface IGNavigationBarButtonView : UIView
@end
#import "../../InstagramHeaders.h"
#import "../../Settings/SCISettingsViewController.h"

@interface UIView (SCInstaSettingsHook)
- (void)sci_attachSettingsLongPressIfNeeded;
- (void)sci_handleSettingsLongPress:(UILongPressGestureRecognizer *)sender;
@end

static BOOL SCIsProfileMoreIdentifier(NSString *aid) {
    if (!aid || ![aid isKindOfClass:[NSString class]]) return NO;
    return ([aid isEqualToString:@"profile-more-bar-button"] ||
            [aid isEqualToString:@"profile-more-button"] ||
            [aid isEqualToString:@"profile-settings-button"] ||
            [aid containsString:@"profile-more"]);
}

// Recursively check if the view or any of its children has the hamburger accessibilityIdentifier
static BOOL SCViewTreeIsHamburgerButton(UIView *view) {
    if (!view) return NO;
    if (SCIsProfileMoreIdentifier(view.accessibilityIdentifier)) return YES;

    for (UIView *sub in view.subviews) {
        if (SCIsProfileMoreIdentifier(sub.accessibilityIdentifier)) {
            return YES;
        }
    }
    return NO;
}

// ─────────────────────────────────────────────────────────────────────────────
// Universal UIView category + hook so it works on ObjC wrappers, Swift views,
// and iOS 26 Liquid Glass NavigationBarPlatterContainer buttons
// ─────────────────────────────────────────────────────────────────────────────
%hook UIView

%new - (void)sci_attachSettingsLongPressIfNeeded {
    self.userInteractionEnabled = YES;

    for (UIGestureRecognizer *gr in self.gestureRecognizers) {
        if ([gr isKindOfClass:[UILongPressGestureRecognizer class]] &&
            [NSStringFromClass([gr class]) isEqualToString:@"UILongPressGestureRecognizer"]) {
            // Check if we already added our 0.45s recognizer
            UILongPressGestureRecognizer *lp = (UILongPressGestureRecognizer *)gr;
            if (fabs(lp.minimumPressDuration - 0.45) < 0.01) {
                return;
            }
        }
    }

    NSLog(@"[SCInsta] Attaching settings long-press to %@ (aid: %@)", NSStringFromClass([self class]), self.accessibilityIdentifier);

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(sci_handleSettingsLongPress:)];
    lp.minimumPressDuration = 0.45;
    lp.cancelsTouchesInView = YES;

    for (UIGestureRecognizer *existing in self.gestureRecognizers) {
        [existing requireGestureRecognizerToFail:lp];
    }

    [self addGestureRecognizer:lp];
}

%new - (void)sci_handleSettingsLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    NSLog(@"[SCInsta] Opening SCInsta settings via long-press on %@", NSStringFromClass([self class]));
    UIWindow *win = self.window ?: [[UIApplication sharedApplication] keyWindow];
    [SCIUtils showSettingsVC:win];
}

// Catch when Instagram assigns the accessibilityIdentifier AFTER didMoveToWindow
- (void)setAccessibilityIdentifier:(NSString *)accessibilityIdentifier {
    %orig(accessibilityIdentifier);

    if (SCIsProfileMoreIdentifier(accessibilityIdentifier)) {
        [self sci_attachSettingsLongPressIfNeeded];
        if (self.superview && [NSStringFromClass([self.superview class]) containsString:@"NavigationBarButton"]) {
            [self.superview sci_attachSettingsLongPressIfNeeded];
        }
    }
}

%end

// ─────────────────────────────────────────────────────────────────────────────
// 1. v454+ ObjC wrapper: IGNavigationBarButtonView
// ─────────────────────────────────────────────────────────────────────────────
%hook IGNavigationBarButtonView

- (void)didMoveToWindow {
    %orig;
    if (SCViewTreeIsHamburgerButton(self)) {
        [self sci_attachSettingsLongPressIfNeeded];
    }
}

- (void)layoutSubviews {
    %orig;
    if (SCViewTreeIsHamburgerButton(self)) {
        [self sci_attachSettingsLongPressIfNeeded];
    }
}

%end

// ─────────────────────────────────────────────────────────────────────────────
// 2. v454+ Swift class: _TtC19IGProfileNavigation24IGBadgedNavigationButton
//    (Hooked dynamically in %ctor below so Theos doesn't choke on the Swift name)
// ─────────────────────────────────────────────────────────────────────────────
%group SwiftBadgedNavButtonGroup

%hook IGBadgedNavigationButtonSwift

- (void)didMoveToWindow {
    %orig;
    UIView *v = (UIView *)self;
    if (SCViewTreeIsHamburgerButton(v) || [v.accessibilityIdentifier containsString:@"more"]) {
        [v sci_attachSettingsLongPressIfNeeded];
        if (v.superview) {
            [v.superview sci_attachSettingsLongPressIfNeeded];
        }
    }
}

- (void)layoutSubviews {
    %orig;
    UIView *v = (UIView *)self;
    if (SCViewTreeIsHamburgerButton(v) || [v.accessibilityIdentifier containsString:@"more"]) {
        [v sci_attachSettingsLongPressIfNeeded];
        if (v.superview) {
            [v.superview sci_attachSettingsLongPressIfNeeded];
        }
    }
}

%end

%end

// ─────────────────────────────────────────────────────────────────────────────
// 3. Legacy fallback: Pure ObjC IGBadgedNavigationButton
// ─────────────────────────────────────────────────────────────────────────────
%hook IGBadgedNavigationButton

- (void)didMoveToWindow {
    %orig;
    UIView *v = (UIView *)self;
    NSString *aid = v.accessibilityIdentifier;
    if (aid && ([aid containsString:@"more"] || [aid containsString:@"settings"])) {
        [v sci_attachSettingsLongPressIfNeeded];
    }
}

%end

// ─────────────────────────────────────────────────────────────────────────────
// 4. Home tab long-press
// ─────────────────────────────────────────────────────────────────────────────
%hook IGTabBarButton

- (void)didMoveToSuperview {
    %orig;
    UIView *v = (UIView *)self;
    if (![v.accessibilityIdentifier isEqualToString:@"mainfeed-tab"]) return;
    [v sci_attachSettingsLongPressIfNeeded];
}

%end

%ctor {
    %init;

    Class swiftBtnCls = objc_getClass("_TtC19IGProfileNavigation24IGBadgedNavigationButton");
    if (swiftBtnCls) {
        %init(SwiftBadgedNavButtonGroup, IGBadgedNavigationButtonSwift = swiftBtnCls);
    }
}
