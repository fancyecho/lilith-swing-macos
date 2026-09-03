#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

int main(void) {
    @autoreleasepool {
        NSArray<NSRunningApplication *> *applications =
            [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.fancyecho.LilithSwing"];
        pid_t swingPID = applications.firstObject.processIdentifier;
        if (swingPID <= 0) {
            fprintf(stderr, "莉莉丝秋千当前未运行。\n");
            return 1;
        }

        CFArrayRef windowInfo = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly,
                                                           kCGNullWindowID);
        NSArray *windows = CFBridgingRelease(windowInfo);
        for (NSDictionary *window in windows) {
            pid_t ownerPID = [window[(id)kCGWindowOwnerPID] intValue];
            if (ownerPID != swingPID) continue;

            NSString *owner = window[(id)kCGWindowOwnerName] ?: @"";
            CGRect bounds = CGRectZero;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)window[(id)kCGWindowBounds],
                                                   &bounds);

            printf("id=%d owner=%s name=%s layer=%d alpha=%.2f bounds=(%.0f,%.0f %.0fx%.0f)\n",
                   [window[(id)kCGWindowNumber] intValue],
                   owner.UTF8String,
                   [window[(id)kCGWindowName] ?: @"" UTF8String],
                   [window[(id)kCGWindowLayer] intValue],
                   [window[(id)kCGWindowAlpha] doubleValue],
                   bounds.origin.x,
                   bounds.origin.y,
                   bounds.size.width,
                   bounds.size.height);
        }
    }
    return 0;
}
