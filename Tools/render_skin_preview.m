#import <AppKit/AppKit.h>
#import "Skins/Mucha/MuchaSkin.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 3) {
            fprintf(stderr, "usage: render_skin_preview <skin-root> <output.png>\n");
            return 2;
        }

        [NSApplication sharedApplication];
        NSURL *skinRoot = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]
                                     isDirectory:YES];
        NSError *error = nil;
        MuchaSkin *skin = [[MuchaSkin alloc] initWithResourceRoot:skinRoot error:&error];
        if (!skin) {
            fprintf(stderr, "unable to load skin: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }

        const NSInteger width = 520;
        const NSInteger height = 720;
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:NULL
                          pixelsWide:width
                          pixelsHigh:height
                       bitsPerSample:8
                     samplesPerPixel:4
                            hasAlpha:YES
                            isPlanar:NO
                      colorSpaceName:NSCalibratedRGBColorSpace
                         bytesPerRow:0
                        bitsPerPixel:0];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];

        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext.currentContext = context;

        [[NSColor colorWithCalibratedWhite:0.94 alpha:1.0] setFill];
        NSRectFill(NSMakeRect(0.0, 0.0, width / 2.0, height));
        [[NSColor colorWithCalibratedRed:0.085 green:0.082 blue:0.072 alpha:1.0] setFill];
        NSRectFill(NSMakeRect(width / 2.0, 0.0, width / 2.0, height));

        NSSize seatSize = skin.seatWindowSize;
        CGFloat seatX = (width - seatSize.width) / 2.0;
        CGFloat seatY = 118.0;
        CGFloat vineBottom = seatY + seatSize.height - 2.0;
        CGFloat ornamentY = height - skin.topOrnamentHeight - 16.0;
        CGFloat vineHeight = ornamentY + 4.0 - vineBottom;

        [skin drawTopOrnamentInRect:NSMakeRect(seatX,
                                               ornamentY,
                                               seatSize.width,
                                               skin.topOrnamentHeight)];
        [skin drawVineInRect:NSMakeRect(seatX + skin.leftAttachmentX - skin.vineWindowWidth / 2.0,
                                        vineBottom,
                                        skin.vineWindowWidth,
                                        vineHeight)
                    mirrored:NO
              revealProgress:1.0];
        [skin drawVineInRect:NSMakeRect(seatX + skin.rightAttachmentX - skin.vineWindowWidth / 2.0,
                                        vineBottom,
                                        skin.vineWindowWidth,
                                        vineHeight)
                    mirrored:YES
              revealProgress:1.0];
        [skin drawSeatInRect:NSMakeRect(seatX, seatY, seatSize.width, seatSize.height)];

        NSGraphicsContext.currentContext = nil;
        [NSGraphicsContext restoreGraphicsState];

        NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        NSString *outputPath = [NSString stringWithUTF8String:argv[2]];
        if (![png writeToFile:outputPath options:NSDataWritingAtomic error:&error]) {
            fprintf(stderr, "unable to write preview: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }
        printf("Rendered %s\n", outputPath.UTF8String);
    }
    return 0;
}
