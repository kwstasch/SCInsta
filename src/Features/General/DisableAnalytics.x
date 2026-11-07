#import "../../Utils.h"

// ─────────────────────────────────────────────────────────────────────────────
// DISABLE META ANALYTICS & TELEMETRY (Piko style)
// Strips analytics upload, event logging, and background telemetry pings
// ─────────────────────────────────────────────────────────────────────────────

%hook FBAnalyticsLogging

- (void)logEventWithName:(id)arg1 category:(id)arg2 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig;
}

- (void)logEvent:(id)arg1 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig;
}

- (void)logEvent:(id)arg1 extras:(id)arg2 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig;
}

- (void)logEventImmediately:(id)arg1 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig;
}

%end
