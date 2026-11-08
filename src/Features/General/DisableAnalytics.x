#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../../Utils.h"

// SCInsta: Disable Meta / Instagram Analytics & Telemetry Tracking
// Intercepts and blocks client telemetry, event queueing, and network upload tasks to Meta servers.

@interface IGAnalyticsProcessingQueue : NSObject
- (void)processTask:(id)task;
@end

@interface FBSDKAppEvents : NSObject
+ (void)logEvent:(id)arg1;
+ (void)logEvent:(id)arg1 parameters:(id)arg2;
+ (void)logEvent:(id)arg1 valueToSum:(double)arg2 parameters:(id)arg3;
+ (void)logPurchase:(double)arg1 currency:(id)arg2;
+ (void)logPurchase:(double)arg1 currency:(id)arg2 parameters:(id)arg3;
+ (void)logPushNotificationOpen:(id)arg1;
@end

@interface IGAnalyticsNavigationState : NSObject
- (void)applyToEvent:(id)event;
@end

@interface IGAnalyticsWaterfall : NSObject
- (void)logStepBackwardWithName:(id)arg1;
- (void)logStepForwardWithName:(id)arg1;
@end

static inline BOOL SCIIsAnalyticsURL(NSURL *url) {
    if (!url) return NO;
    NSString *host = url.host.lowercaseString;
    NSString *path = url.path.lowercaseString;

    if (host.length > 0) {
        if ([host containsString:@"graph.instagram.com"] ||
            [host containsString:@"graph.facebook.com"] ||
            [host containsString:@"b-graph.facebook.com"]) {
            return YES;
        }
    }
    if (path.length > 0) {
        if ([path containsString:@"logging_client_events"] ||
            [path containsString:@"pigeon_nest"] ||
            [path containsString:@"pigeon_health_metrics"] ||
            [path containsString:@"meta_checkout_engine_logger"] ||
            [path containsString:@"mldw_get_feature_group"]) {
            return YES;
        }
    }
    return NO;
}

// MARK: - Layer 1: Network Upload Interception (NSURLSession)

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    if ([SCIUtils getBoolPref:@"disable_analytics"] && SCIIsAnalyticsURL(request.URL)) {
        NSURLSessionDataTask *task = %orig(request);
        [task cancel];
        return task;
    }
    return %orig(request);
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(id)completionHandler {
    if ([SCIUtils getBoolPref:@"disable_analytics"] && SCIIsAnalyticsURL(request.URL)) {
        NSURLSessionDataTask *task = %orig(request, completionHandler);
        [task cancel];
        return task;
    }
    return %orig(request, completionHandler);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData {
    if ([SCIUtils getBoolPref:@"disable_analytics"] && SCIIsAnalyticsURL(request.URL)) {
        NSURLSessionUploadTask *task = %orig(request, bodyData);
        [task cancel];
        return task;
    }
    return %orig(request, bodyData);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(id)completionHandler {
    if ([SCIUtils getBoolPref:@"disable_analytics"] && SCIIsAnalyticsURL(request.URL)) {
        NSURLSessionUploadTask *task = %orig(request, bodyData, completionHandler);
        [task cancel];
        return task;
    }
    return %orig(request, bodyData, completionHandler);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL {
    if ([SCIUtils getBoolPref:@"disable_analytics"] && SCIIsAnalyticsURL(request.URL)) {
        NSURLSessionUploadTask *task = %orig(request, fileURL);
        [task cancel];
        return task;
    }
    return %orig(request, fileURL);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(id)completionHandler {
    if ([SCIUtils getBoolPref:@"disable_analytics"] && SCIIsAnalyticsURL(request.URL)) {
        NSURLSessionUploadTask *task = %orig(request, fileURL, completionHandler);
        [task cancel];
        return task;
    }
    return %orig(request, fileURL, completionHandler);
}

%end

// MARK: - Layer 2: Internal Event Processing Queue

%hook IGAnalyticsProcessingQueue
- (void)processTask:(id)task {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) {
        return;
    }
    %orig(task);
}
%end

// MARK: - Layer 3: Facebook App Events SDK

%hook FBSDKAppEvents
+ (void)logEvent:(id)arg1 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig(arg1);
}
+ (void)logEvent:(id)arg1 parameters:(id)arg2 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig(arg1, arg2);
}
+ (void)logEvent:(id)arg1 valueToSum:(double)arg2 parameters:(id)arg3 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig(arg1, arg2, arg3);
}
+ (void)logPurchase:(double)arg1 currency:(id)arg2 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig(arg1, arg2);
}
+ (void)logPurchase:(double)arg1 currency:(id)arg2 parameters:(id)arg3 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig(arg1, arg2, arg3);
}
+ (void)logPushNotificationOpen:(id)arg1 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) return;
    %orig(arg1);
}
%end

// MARK: - Layer 4: Navigation State & Waterfall Tracking

%hook IGAnalyticsNavigationState
- (void)applyToEvent:(id)event {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) {
        return;
    }
    %orig(event);
}
%end

%hook IGAnalyticsWaterfall
- (void)logStepBackwardWithName:(id)arg1 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) {
        return;
    }
    %orig(arg1);
}
- (void)logStepForwardWithName:(id)arg1 {
    if ([SCIUtils getBoolPref:@"disable_analytics"]) {
        return;
    }
    %orig(arg1);
}
%end
