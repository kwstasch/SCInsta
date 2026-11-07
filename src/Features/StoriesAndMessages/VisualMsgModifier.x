#import "../../Utils.h"

// IGDirectVisualMessage.viewMode values:
// 0 = View Once (expires after 1 view)
// 1 = Replayable (can be replayed)

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

// --- BUG FIX: "Tap to view photo" label not clearing after viewing ---
//
// IGDirectVisualMessagePreviewViewModel drives the DM bubble UI.
// Even though viewMode is spoofed to 1 (replayable), the cell still queries
// isMediaUnseen on this ViewModel to decide whether to show "Tap to view photo".
// Since the server-side state is never actually changed (we only spoof locally),
// isMediaUnseen stays YES and the label never clears after the user opens the photo.
//
// Fix: when the bypass is active, return NO from isMediaUnseen so the label clears,
// and return YES from isMediaReplayable so the replay button is shown.
// Both selectors and the class are confirmed present in Instagram v454.1.0.
//
%hook IGDirectVisualMessagePreviewViewModel

// Returns NO = media has been seen = clear the "Tap to view" label
- (BOOL)isMediaUnseen {
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"]) {
        return NO;
    }
    return %orig;
}

// Returns YES = show replay button/icon
- (BOOL)isMediaReplayable {
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"]) {
        return YES;
    }
    return %orig;
}

%end
