#import "../../Utils.h"

%hook IGDirectVisualMessage

- (NSInteger)viewMode {
    NSInteger mode = %orig;
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"]) {
        if (mode == 0) {
            mode = 1;
            NSLog(@"[SCInsta] Modifying visual message from read-once to replayable");
        }
    }
    return mode;
}

%end

%hook IGDirectVisualMessagePreviewViewModel

// Clears "Tap to view photo" label after opening
- (BOOL)isMediaUnseen {
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"]) {
        return NO;
    }
    return %orig;
}

// Shows the replay button
- (BOOL)isMediaReplayable {
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"]) {
        return YES;
    }
    return %orig;
}

%end
