#import "../../InstagramHeaders.h"
#import "../../Settings/SCISettingsViewController.h"

// Forward interface so clang knows IGNavigationBarButtonView is a UIView
@interface IGNavigationBarButtonView : UIView
- (void)sci_addLongPressIfNeeded;
- (void)sci_handleLongPress:(UILongPressGestureRecognizer *)sender;
@end

// ─────────────────────────────────────────────────────────────────────────────
// HAMBURGER / PROFILE MORE BUTTON  (v454+)
//
// In Instagram v454 IGBadgedNavigationButton moved into the IGProfileNavigation
// Swift module (_TtC19IGProfileNavigation24IGBadgedNavigationButton).
// Theos cannot %hook Swift-mangled classes by their short ObjC name when they
// live inside a Swift module — the hook silently does nothing.
//
// The hamburger ("more") button in the profile header is now backed by
// IGNavigationBarButtonView (ObjC, from IGProfileUtils), which wraps the Swift
// button and is what actually appears in the view hierarchy.
// Its accessibilityIdentifier is "profile-more-bar-button" or "profile-more-button".
// ─────────────────────────────────────────────────────────────────────────────

// v454+ — ObjC wrapper for profile nav buttons (hamburger included)
%hook IGNavigationBarButtonView

- (void)didMoveToWindow {
    %orig;

    NSString *aid = self.accessibilityIdentifier;
    if (!aid) return;

    if ([aid isEqualToString:@"profile-more-bar-button"] ||
        [aid isEqualToString:@"profile-more-button"] ||
        [aid containsString:@"more"] ||
        [aid containsString:@"settings"]) {
        [self sci_addLongPressIfNeeded];
    }
}

%new - (void)sci_addLongPressIfNeeded {
    for (UIGestureRecognizer *gr in self.gestureRecognizers) {
        if ([gr isKindOfClass:[UILongPressGestureRecognizer class]]) return;
    }
    NSLog(@"[SCInsta] Adding tweak settings long-press on IGNavigationBarButtonView (%@)", self.accessibilityIdentifier);
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(sci_handleLongPress:)];
    lp.minimumPressDuration = 0.5;
    [self addGestureRecognizer:lp];
}

%new - (void)sci_handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    NSLog(@"[SCInsta] Tweak settings opened from hamburger/more button");
    [SCIUtils showSettingsVC:[self window]];
}

%end

// ─────────────────────────────────────────────────────────────────────────────
// Fallback: older Instagram versions used IGBadgedNavigationButton (pure ObjC)
// ─────────────────────────────────────────────────────────────────────────────
%hook IGBadgedNavigationButton

- (void)didMoveToWindow {
    %orig;

    NSString *aid = self.accessibilityIdentifier;
    if (aid && ([aid containsString:@"more"] || [aid containsString:@"settings"])) {
        [self addLongPressGestureRecognizer];
    }
}

%new - (void)addLongPressGestureRecognizer {
    if ([self.gestureRecognizers count] == 0) {
        NSLog(@"[SCInsta] Adding tweak settings long press gesture recognizer (legacy)");
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPress];
    }
}

%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    [SCIUtils showSettingsVC:[self window]];
}

%end

// ─────────────────────────────────────────────────────────────────────────────
// Home tab long-press (unchanged — already working)
// ─────────────────────────────────────────────────────────────────────────────
%hook IGTabBarButton

- (void)didMoveToSuperview {
    %orig;

    if (![self.accessibilityIdentifier isEqualToString:@"mainfeed-tab"]) return;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.3;

    for (UIGestureRecognizer *existing in self.gestureRecognizers) {
        [existing requireGestureRecognizerToFail:longPress];
    }

    [self addGestureRecognizer:longPress];
}

%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    [SCIUtils showSettingsVC:[self window]];
}

%end
