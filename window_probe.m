#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

int main(void) {
    @autoreleasepool {
        CFArrayRef windowInfo = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly,
                                                           kCGNullWindowID);
        NSArray *windows = CFBridgingRelease(windowInfo);
        for (NSDictionary *window in windows) {
            NSString *owner = window[(id)kCGWindowOwnerName];
            CGRect bounds = CGRectZero;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)window[(id)kCGWindowBounds],
                                                   &bounds);
            BOOL isSwingOwner = [owner containsString:@"莉莉丝秋千"] ||
                                [owner containsString:@"LilithSwing"];
            BOOL hasSwingDimensions = (fabs(bounds.size.width - 248.0) < 1.0 &&
                                       fabs(bounds.size.height - 72.0) < 1.0) ||
                                      (fabs(bounds.size.width - 12.0) < 1.0 &&
                                       fabs(bounds.size.height - 188.0) < 1.0) ||
                                      (fabs(bounds.size.width - 56.0) < 1.0 &&
                                       fabs(bounds.size.height - 18.0) < 1.0);
            if (!isSwingOwner && !hasSwingDimensions) continue;

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
