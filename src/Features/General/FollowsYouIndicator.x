#import "../../InstagramHeaders.h"
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// FOLLOWS YOU INDICATOR (Σε ακολουθεί)
// Displays whether a user follows you back on their profile and across the app
// ─────────────────────────────────────────────────────────────────────────────

static NSString *const kFollowsYouText = @"Σε ακολουθεί";
static NSString *const kNotFollowingText = @"Δεν σε ακολουθεί";

// Helper to sanitize and process button title
static id sci_processTitle(id orig, NSInteger buttonState, BOOL userFollowsCurrentUser) {
    if (![SCIUtils getBoolPref:@"follows_you_indicator"]) {
        return orig;
    }

    if (userFollowsCurrentUser) {
        return kFollowsYouText;
    } else if (buttonState == 1) { // Following them, but they do not follow back
        return kNotFollowingText;
    }

    return orig;
}

// Helper to recursively update any UILabel inside the follow button if needed
static void sci_updateLabelRecursive(UIView *view, BOOL followsYou, NSInteger buttonState) {
    if (!view) return;
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (label.text.length > 0) {
            NSString *current = label.text;
            if ([current isEqualToString:kFollowsYouText] || [current isEqualToString:kNotFollowingText]) {
                return;
            }
            for (NSString *tag in @[@" • Σε ακολουθεί", @" • Δεν σε ακολουθεί", @" • Follows you", @" • Not following", @" (Σε ακολουθεί)", @" (Δεν σε ακολουθεί)"]) {
                current = [current stringByReplacingOccurrencesOfString:tag withString:@""];
            }
            if (followsYou) {
                label.text = kFollowsYouText;
            } else if (buttonState == 1) {
                label.text = kNotFollowingText;
            }
            [label sizeToFit];
            return;
        }
    }
    for (UIView *sub in view.subviews) {
        sci_updateLabelRecursive(sub, followsYou, buttonState);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Follow button title engine hooks (Swift + ObjC)
// ─────────────────────────────────────────────────────────────────────────────

%hook _TtC20IGFollowButtonShared19IGFollowButtonTitle

+ (id)titleFor:(NSInteger)buttonState viewConfiguration:(id)viewConfiguration userFollowsCurrentUser:(BOOL)userFollowsCurrentUser {
    id orig = %orig;
    return sci_processTitle(orig, buttonState, userFollowsCurrentUser);
}

- (id)titleFor:(NSInteger)buttonState viewConfiguration:(id)viewConfiguration userFollowsCurrentUser:(BOOL)userFollowsCurrentUser {
    id orig = %orig;
    return sci_processTitle(orig, buttonState, userFollowsCurrentUser);
}

%end

%hook IGFollowButtonTitle

+ (id)titleFor:(NSInteger)buttonState viewConfiguration:(id)viewConfiguration userFollowsCurrentUser:(BOOL)userFollowsCurrentUser {
    id orig = %orig;
    return sci_processTitle(orig, buttonState, userFollowsCurrentUser);
}

- (id)titleFor:(NSInteger)buttonState viewConfiguration:(id)viewConfiguration userFollowsCurrentUser:(BOOL)userFollowsCurrentUser {
    id orig = %orig;
    return sci_processTitle(orig, buttonState, userFollowsCurrentUser);
}

%end

// ─────────────────────────────────────────────────────────────────────────────
// 2. Follow controller hooks (Swift + ObjC)
// ─────────────────────────────────────────────────────────────────────────────

@interface NSObject (SCIFollowsBadge)
- (void)sci_refreshFollowsBadge;
@end

%hook _TtC11IGFollowing18IGFollowController

- (void)updateFollowButtonState {
    %orig;
    [self sci_refreshFollowsBadge];
}

- (void)setUserFollowsCurrentUser:(BOOL)userFollows {
    %orig;
    [self sci_refreshFollowsBadge];
}

- (void)userValueChanged:(id)user {
    %orig;
    [self sci_refreshFollowsBadge];
}

%new
- (void)sci_refreshFollowsBadge {
    if (![SCIUtils getBoolPref:@"follows_you_indicator"]) return;

    IGUser *user = nil;
    @try {
        user = [self valueForKey:@"user"] ?: [self valueForKey:@"_user"];
    } @catch (NSException *e) {}

    BOOL followsYou = NO;
    if ([self respondsToSelector:@selector(userFollowsCurrentUser)]) {
        followsYou = [self userFollowsCurrentUser];
    } else if (user) {
        if ([user respondsToSelector:@selector(followsCurrentUser)]) {
            followsYou = [user followsCurrentUser];
        } else if ([user respondsToSelector:@selector(isFollowingCurrentUser)]) {
            followsYou = [(id)user isFollowingCurrentUser];
        }
    }

    UIControl *btn = nil;
    @try {
        btn = [self valueForKey:@"followButton"] ?: [self valueForKey:@"_followButton"];
    } @catch (NSException *e) {}

    if (!btn) return;

    NSInteger followState = 0;
    if (user && [user respondsToSelector:@selector(followStatus)]) {
        followState = [user followStatus];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        sci_updateLabelRecursive(btn, followsYou, followState);
        [btn setNeedsLayout];
    });
}

%end

%hook IGFollowController

- (void)updateFollowButtonState {
    %orig;
    [self sci_refreshFollowsBadge];
}

- (void)setUserFollowsCurrentUser:(BOOL)userFollows {
    %orig;
    [self sci_refreshFollowsBadge];
}

- (void)userValueChanged:(id)user {
    %orig;
    [self sci_refreshFollowsBadge];
}

%new
- (void)sci_refreshFollowsBadge {
    if (![SCIUtils getBoolPref:@"follows_you_indicator"]) return;

    IGUser *user = nil;
    @try {
        user = [self valueForKey:@"user"] ?: [self valueForKey:@"_user"];
    } @catch (NSException *e) {}

    BOOL followsYou = NO;
    if ([self respondsToSelector:@selector(userFollowsCurrentUser)]) {
        followsYou = [self userFollowsCurrentUser];
    } else if (user) {
        if ([user respondsToSelector:@selector(followsCurrentUser)]) {
            followsYou = [user followsCurrentUser];
        } else if ([user respondsToSelector:@selector(isFollowingCurrentUser)]) {
            followsYou = [(id)user isFollowingCurrentUser];
        }
    }

    UIControl *btn = nil;
    @try {
        btn = [self valueForKey:@"followButton"] ?: [self valueForKey:@"_followButton"];
    } @catch (NSException *e) {}

    if (!btn) return;

    NSInteger followState = 0;
    if (user && [user respondsToSelector:@selector(followStatus)]) {
        followState = [user followStatus];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        sci_updateLabelRecursive(btn, followsYou, followState);
        [btn setNeedsLayout];
    });
}

%end
