#import "SwingSupportGeometry.h"

NSRect SwingSupportFrameForSeat(NSRect seatFrame, NSRect screenFrame) {
    CGFloat bottom = MIN(NSMinY(seatFrame), NSMinY(screenFrame));
    return NSMakeRect(NSMinX(seatFrame), bottom, NSWidth(seatFrame),
                      MAX(1.0, NSMaxY(seatFrame) - bottom));
}
