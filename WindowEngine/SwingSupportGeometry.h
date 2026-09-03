#import <AppKit/AppKit.h>

// Keep the visible seat's top and width; extend only its game-facing support
// down to the display floor. Coordinates are AppKit screen points.
NSRect SwingSupportFrameForSeat(NSRect seatFrame, NSRect screenFrame);
