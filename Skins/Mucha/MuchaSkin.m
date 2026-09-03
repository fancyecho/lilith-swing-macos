#import "MuchaSkin.h"

static NSColor *MuchaColor(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

@interface MuchaSkin ()
@property(nonatomic, strong) SwingSkinAssetCatalog *catalog;
@end

@implementation MuchaSkin

- (instancetype)initWithResourceRoot:(NSURL *)resourceRoot error:(NSError **)error {
    self = [super init];
    if (!self) return nil;
    self.catalog = [[SwingSkinAssetCatalog alloc] initWithRootURL:resourceRoot error:error];
    return self.catalog ? self : nil;
}

- (NSString *)identifier {
    return [self.catalog stringForKey:@"identifier" fallback:@"mucha-iris"];
}

- (NSString *)displayName {
    return [self.catalog stringForKey:@"displayName" fallback:@"穆夏 · 鸢尾"];
}

- (NSSize)seatWindowSize {
    return NSMakeSize([self.catalog metricForKey:@"seatWidth" fallback:248.0],
                      [self.catalog metricForKey:@"seatHeight" fallback:104.0]);
}

- (CGFloat)vineWindowWidth {
    return [self.catalog metricForKey:@"vineWidth" fallback:28.0];
}

- (CGFloat)topOrnamentHeight {
    return [self.catalog metricForKey:@"topOrnamentHeight" fallback:28.0];
}

- (CGFloat)leftAttachmentX {
    return [self.catalog metricForKey:@"leftAttachmentX" fallback:38.0];
}

- (CGFloat)rightAttachmentX {
    return [self.catalog metricForKey:@"rightAttachmentX" fallback:210.0];
}

- (void)drawAssetNamed:(NSString *)name inRect:(NSRect)targetRect fraction:(CGFloat)fraction {
    NSImage *image = [self.catalog imageNamed:name];
    NSRect sourceRect = [self.catalog sourceRectForAssetNamed:name];
    if (!image || NSIsEmptyRect(sourceRect)) return;

    NSImageInterpolation previous = NSGraphicsContext.currentContext.imageInterpolation;
    NSGraphicsContext.currentContext.imageInterpolation = NSImageInterpolationHigh;
    [image drawInRect:targetRect
             fromRect:sourceRect
            operation:NSCompositingOperationSourceOver
             fraction:fraction
       respectFlipped:NO
                hints:nil];
    NSGraphicsContext.currentContext.imageInterpolation = previous;
}

- (void)drawSeatInRect:(NSRect)rect {
    NSRect sourceRect = [self.catalog sourceRectForAssetNamed:@"seat"];
    CGFloat targetHeight = NSWidth(rect) * NSHeight(sourceRect) / MAX(1.0, NSWidth(sourceRect));
    NSRect targetRect = NSMakeRect(NSMinX(rect),
                                   NSMaxY(rect) - targetHeight,
                                   NSWidth(rect),
                                   targetHeight);

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = NSMakeSize(0.0, -1.0);
    shadow.shadowBlurRadius = 2.5;
    shadow.shadowColor = MuchaColor(0.15, 0.11, 0.04, 0.18);
    [NSGraphicsContext saveGraphicsState];
    [shadow set];
    [self drawAssetNamed:@"seat" inRect:targetRect fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];

    for (NSNumber *position in @[@(self.leftAttachmentX), @(self.rightAttachmentX)]) {
        CGFloat x = position.doubleValue;
        NSRect outerRect = NSMakeRect(x - 4.8, NSMaxY(rect) - 11.2, 9.6, 9.6);
        NSBezierPath *outer = [NSBezierPath bezierPathWithOvalInRect:outerRect];
        NSGradient *metal = [[NSGradient alloc]
            initWithStartingColor:MuchaColor(0.91, 0.76, 0.37, 1.0)
                      endingColor:MuchaColor(0.38, 0.25, 0.08, 1.0)];
        [metal drawInBezierPath:outer angle:-62.0];
        [MuchaColor(0.20, 0.17, 0.09, 0.96) setStroke];
        outer.lineWidth = 0.8;
        [outer stroke];

        NSBezierPath *opening = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(outerRect, 3.0, 3.0)];
        [MuchaColor(0.10, 0.15, 0.09, 0.96) setFill];
        [opening fill];
    }
}

- (void)drawVineInRect:(NSRect)rect
              mirrored:(BOOL)mirrored
        revealProgress:(CGFloat)revealProgress {
    CGFloat progress = MIN(1.0, MAX(0.0, revealProgress));
    if (progress <= 0.001) return;

    CGFloat cutoff = NSMinY(rect) + NSHeight(rect) * (1.0 - progress);
    [NSGraphicsContext saveGraphicsState];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(NSMinX(rect),
                                                 cutoff,
                                                 NSWidth(rect),
                                                 NSMaxY(rect) - cutoff)] addClip];

    if (mirrored) {
        NSAffineTransform *mirror = [NSAffineTransform transform];
        [mirror translateXBy:2.0 * NSMidX(rect) yBy:0.0];
        [mirror scaleXBy:-1.0 yBy:1.0];
        [mirror concat];
    }

    NSBezierPath *continuousStem = [NSBezierPath bezierPath];
    [continuousStem moveToPoint:NSMakePoint(NSMidX(rect), NSMinY(rect) - 2.0)];
    [continuousStem lineToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect) + 2.0)];
    [MuchaColor(0.20, 0.25, 0.12, 0.82) setStroke];
    continuousStem.lineWidth = 2.4;
    [continuousStem stroke];
    [MuchaColor(0.69, 0.48, 0.18, 0.64) setStroke];
    continuousStem.lineWidth = 0.72;
    [continuousStem stroke];

    NSRect sourceRect = [self.catalog sourceRectForAssetNamed:@"vine"];
    CGFloat tileHeight = NSWidth(rect) * NSHeight(sourceRect) / MAX(1.0, NSWidth(sourceRect));
    tileHeight = MAX(42.0, tileHeight);
    CGFloat step = tileHeight - 0.65;
    for (CGFloat y = NSMinY(rect) - 0.3; y < NSMaxY(rect) + tileHeight; y += step) {
        [self drawAssetNamed:@"vine"
                      inRect:NSMakeRect(NSMinX(rect), y, NSWidth(rect), tileHeight)
                    fraction:0.98];
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawTopOrnamentInRect:(NSRect)rect {
    CGFloat leftX = NSMinX(rect) + self.leftAttachmentX;
    CGFloat rightX = NSMinX(rect) + self.rightAttachmentX;
    NSRect sourceRect = [self.catalog sourceRectForAssetNamed:@"topOrnament"];
    if (NSIsEmptyRect(sourceRect)) return;

    // The complete ornament is fitted into the shallow support window as one
    // asset. Its rosette centres align with the two vines, so no source-image
    // fragments can hang outside the window and appear clipped at screen top.
    CGFloat targetWidth = rightX - leftX + 12.0;
    CGFloat targetHeight = targetWidth * NSHeight(sourceRect) / MAX(1.0, NSWidth(sourceRect));
    targetHeight = MIN(NSHeight(rect) - 1.0, targetHeight);
    NSRect targetRect = NSMakeRect(leftX - 6.0,
                                   NSMidY(rect) - targetHeight / 2.0,
                                   targetWidth,
                                   targetHeight);
    [self drawAssetNamed:@"topOrnament" inRect:targetRect fraction:1.0];
}

@end
