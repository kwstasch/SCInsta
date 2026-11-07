#import "../../InstagramHeaders.h"
#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// FOLLOWS YOU INDICATOR
// Displays whether a user follows you back on their profile
// ─────────────────────────────────────────────────────────────────────────────

@interface IGFollowController (SCIFollowsBadge)
- (void)sci_updateFollowsBadge;
@end

%hook IGFollowController

- (void)setUser:(id)user {
    %orig;
    [self sci_updateFollowsBadge];
}

- (void)_didPressFollowButton {
    %orig;
    [self sci_updateFollowsBadge];
}

%new
- (void)sci_updateFollowsBadge {
    if (![SCIUtils getBoolPref:@"follows_you_indicator"]) return;

    IGUser *user = self.user;
    if (!user) return;

    BOOL followsYou = NO;
    if ([user respondsToSelector:@selector(followsCurrentUser)]) {
        followsYou = [user followsCurrentUser];
    } else if ([user respondsToSelector:@selector(isFollowingCurrentUser)]) {
        followsYou = [user isFollowingCurrentUser];
    }

    UIControl *btn = nil;
    @try {
        btn = [self valueForKey:@"followButton"] ?: [self valueForKey:@"_followButton"];
    } @catch (NSException *e) {}

    if (!btn) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel *targetLabel = nil;
        if ([btn respondsToSelector:@selector(titleLabel)] && [(UIButton *)btn titleLabel]) {
            targetLabel = [(UIButton *)btn titleLabel];
        } else {
            for (UIView *sub in btn.subviews) {
                if ([sub isKindOfClass:[UILabel class]]) {
                    targetLabel = (UILabel *)sub;
                    break;
                }
            }
        }

        if (!targetLabel || !targetLabel.text.length) return;

        NSString *current = targetLabel.text;
        NSString *clean = current;
        for (NSString *tag in @[@" • Follows you", @" • Not following", @" (Follows you)", @" (Not following)"]) {
            clean = [clean stringByReplacingOccurrencesOfString:tag withString:@""];
        }

        if (followsYou) {
            targetLabel.text = [clean stringByAppendingString:@" • Follows you"];
            [btn setNeedsLayout];
        } else if (user.followStatus == 1) { // We follow them, but they don't follow back
            targetLabel.text = [clean stringByAppendingString:@" • Not following"];
            [btn setNeedsLayout];
        }
    });
}

%end
