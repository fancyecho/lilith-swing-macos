#import <AppKit/AppKit.h>
#import <math.h>

static const CGFloat kSeatWidth = 248.0;
static const CGFloat kSeatHeight = 78.0;
static const CGFloat kVineWidth = 26.0;
static const CGFloat kTopOrnamentHeight = 24.0;
static const CGFloat kLeftAttachmentX = 36.0;
static const CGFloat kRightAttachmentX = 212.0;
static const NSTimeInterval kVineRevealDuration = 0.58;
static NSString *const kSeatOriginXKey = @"seatOriginX";
static NSString *const kSeatOriginYKey = @"seatOriginY";

@class SwingController;

static NSColor *SwingColor(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha) {
    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

@interface PassivePanel : NSPanel
@end

@implementation PassivePanel
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }
@end

@interface VineView : NSView
@property(nonatomic) BOOL mirrored;
@property(nonatomic) CGFloat revealProgress;
@end

@implementation VineView

- (BOOL)isFlipped { return NO; }

- (NSBezierPath *)leafPathAtPoint:(NSPoint)point angle:(CGFloat)angle scale:(CGFloat)scale {
    NSBezierPath *leaf = [NSBezierPath bezierPath];
    [leaf moveToPoint:NSMakePoint(0.0, -5.4 * scale)];
    [leaf curveToPoint:NSMakePoint(0.0, 5.8 * scale)
         controlPoint1:NSMakePoint(4.3 * scale, -2.0 * scale)
         controlPoint2:NSMakePoint(4.2 * scale, 3.1 * scale)];
    [leaf curveToPoint:NSMakePoint(0.0, -5.4 * scale)
         controlPoint1:NSMakePoint(-4.1 * scale, 3.0 * scale)
         controlPoint2:NSMakePoint(-4.0 * scale, -2.0 * scale)];
    [leaf closePath];

    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:point.x yBy:point.y];
    [transform rotateByDegrees:angle];
    [leaf transformUsingAffineTransform:transform];
    return leaf;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    (void)dirtyRect;

    CGFloat width = NSWidth(self.bounds);
    CGFloat height = NSHeight(self.bounds);
    if (height <= 1.0 || self.revealProgress <= 0.001) return;

    CGFloat progress = MIN(1.0, MAX(0.0, self.revealProgress));
    CGFloat cutoff = height * (1.0 - progress);
    [NSGraphicsContext saveGraphicsState];
    [[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, cutoff, width, height - cutoff)] addClip];

    CGFloat direction = self.mirrored ? -1.0 : 1.0;
    CGFloat centerX = NSMidX(self.bounds);
    NSBezierPath *vine = [NSBezierPath bezierPath];
    [vine moveToPoint:NSMakePoint(centerX, height + 2.0)];
    CGFloat y = height + 2.0;
    NSInteger segment = 0;
    while (y > -2.0) {
        CGFloat nextY = MAX(-2.0, y - 58.0);
        CGFloat bend = direction * ((segment % 2 == 0) ? 3.0 : -3.0);
        [vine curveToPoint:NSMakePoint(centerX, nextY)
             controlPoint1:NSMakePoint(centerX + bend, y - 18.0)
             controlPoint2:NSMakePoint(centerX - bend, nextY + 18.0)];
        y = nextY;
        segment += 1;
    }

    NSBezierPath *shadow = [vine copy];
    NSAffineTransform *shadowOffset = [NSAffineTransform transform];
    [shadowOffset translateXBy:1.4 yBy:-0.8];
    [shadow transformUsingAffineTransform:shadowOffset];
    [SwingColor(0.10, 0.15, 0.09, 0.34) setStroke];
    shadow.lineWidth = 5.4;
    shadow.lineCapStyle = NSLineCapStyleRound;
    [shadow stroke];

    [SwingColor(0.48, 0.35, 0.14, 0.96) setStroke];
    vine.lineWidth = 4.0;
    vine.lineCapStyle = NSLineCapStyleRound;
    [vine stroke];

    NSBezierPath *greenCore = [vine copy];
    [SwingColor(0.24, 0.36, 0.20, 1.0) setStroke];
    greenCore.lineWidth = 2.3;
    [greenCore stroke];

    NSBezierPath *highlight = [vine copy];
    NSAffineTransform *highlightOffset = [NSAffineTransform transform];
    [highlightOffset translateXBy:-0.65 yBy:0.0];
    [highlight transformUsingAffineTransform:highlightOffset];
    [SwingColor(0.73, 0.72, 0.42, 0.72) setStroke];
    highlight.lineWidth = 0.72;
    [highlight stroke];

    NSInteger leafIndex = 0;
    for (CGFloat leafY = height - 34.0; leafY > 13.0; leafY -= 36.0) {
        if (leafY + 9.0 < cutoff) continue;
        CGFloat side = (leafIndex % 2 == 0 ? 1.0 : -1.0) * direction;
        CGFloat sway = sin(leafY * 0.065) * 1.6;
        CGFloat branchEndX = centerX + side * 6.2 + sway;

        NSBezierPath *branch = [NSBezierPath bezierPath];
        [branch moveToPoint:NSMakePoint(centerX + sway * 0.2, leafY - 1.0)];
        [branch curveToPoint:NSMakePoint(branchEndX, leafY + 2.0)
               controlPoint1:NSMakePoint(centerX + side * 2.4, leafY + 0.2)
               controlPoint2:NSMakePoint(branchEndX - side * 1.6, leafY + 1.4)];
        [SwingColor(0.31, 0.40, 0.20, 0.92) setStroke];
        branch.lineWidth = 1.25;
        [branch stroke];

        CGFloat angle = side > 0.0 ? -42.0 : 42.0;
        NSBezierPath *leaf = [self leafPathAtPoint:NSMakePoint(branchEndX + side * 1.3, leafY + 4.1)
                                             angle:angle
                                             scale:(leafIndex % 3 == 0 ? 0.92 : 0.78)];
        NSGradient *leafGradient = [[NSGradient alloc]
            initWithStartingColor:SwingColor(0.46, 0.55, 0.29, 0.98)
                      endingColor:SwingColor(0.17, 0.29, 0.16, 0.98)];
        [leafGradient drawInBezierPath:leaf angle:(side > 0.0 ? 25.0 : 155.0)];
        [SwingColor(0.68, 0.61, 0.30, 0.72) setStroke];
        leaf.lineWidth = 0.72;
        [leaf stroke];

        NSBezierPath *berry = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(centerX - side * 3.7 - 1.25,
                                                                                 leafY + 12.0,
                                                                                 2.5,
                                                                                 2.5)];
        [SwingColor(0.62, 0.42, 0.22, 0.90) setFill];
        [berry fill];
        leafIndex += 1;
    }

    [NSGraphicsContext restoreGraphicsState];
}

@end

@interface TopOrnamentView : NSView
@end

@implementation TopOrnamentView

- (BOOL)isFlipped { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    (void)dirtyRect;

    NSRect bounds = self.bounds;
    CGFloat leftX = kLeftAttachmentX;
    CGFloat rightX = kRightAttachmentX;
    CGFloat centerX = NSMidX(bounds);

    NSBezierPath *arabesque = [NSBezierPath bezierPath];
    [arabesque moveToPoint:NSMakePoint(leftX, NSMaxY(bounds) + 1.0)];
    [arabesque curveToPoint:NSMakePoint(centerX, 8.0)
              controlPoint1:NSMakePoint(leftX + 24.0, 20.0)
              controlPoint2:NSMakePoint(centerX - 42.0, 8.0)];
    [arabesque curveToPoint:NSMakePoint(rightX, NSMaxY(bounds) + 1.0)
              controlPoint1:NSMakePoint(centerX + 42.0, 8.0)
              controlPoint2:NSMakePoint(rightX - 24.0, 20.0)];
    [SwingColor(0.11, 0.17, 0.10, 0.35) setStroke];
    arabesque.lineWidth = 5.2;
    arabesque.lineCapStyle = NSLineCapStyleRound;
    [arabesque stroke];
    [SwingColor(0.48, 0.36, 0.16, 0.98) setStroke];
    arabesque.lineWidth = 3.8;
    [arabesque stroke];
    [SwingColor(0.31, 0.43, 0.23, 1.0) setStroke];
    arabesque.lineWidth = 2.0;
    [arabesque stroke];

    NSBezierPath *medallion = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(centerX - 10.0, 3.0, 20.0, 18.0)];
    NSGradient *ivory = [[NSGradient alloc]
        initWithStartingColor:SwingColor(0.95, 0.91, 0.75, 0.98)
                  endingColor:SwingColor(0.70, 0.58, 0.30, 0.98)];
    [ivory drawInBezierPath:medallion angle:-90.0];
    [SwingColor(0.37, 0.27, 0.11, 0.94) setStroke];
    medallion.lineWidth = 1.0;
    [medallion stroke];

    NSBezierPath *petal = [NSBezierPath bezierPath];
    [petal moveToPoint:NSMakePoint(centerX, 7.0)];
    [petal curveToPoint:NSMakePoint(centerX, 18.0)
          controlPoint1:NSMakePoint(centerX - 7.0, 12.0)
          controlPoint2:NSMakePoint(centerX - 3.0, 18.0)];
    [petal curveToPoint:NSMakePoint(centerX, 7.0)
          controlPoint1:NSMakePoint(centerX + 3.0, 18.0)
          controlPoint2:NSMakePoint(centerX + 7.0, 12.0)];
    [SwingColor(0.32, 0.43, 0.23, 0.92) setFill];
    [petal fill];

    for (NSNumber *position in @[@(leftX), @(rightX)]) {
        CGFloat x = position.doubleValue;
        NSBezierPath *rosette = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x - 5.0, 14.0, 10.0, 10.0)];
        [SwingColor(0.80, 0.67, 0.32, 0.98) setFill];
        [rosette fill];
        [SwingColor(0.25, 0.31, 0.16, 0.98) setStroke];
        rosette.lineWidth = 1.1;
        [rosette stroke];
        NSBezierPath *center = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x - 1.6, 17.4, 3.2, 3.2)];
        [SwingColor(0.36, 0.23, 0.10, 1.0) setFill];
        [center fill];
    }
}

@end

@interface SwingSeatView : NSView
@property(nonatomic, weak) SwingController *controller;
@property(nonatomic) NSPoint dragStartMouse;
@property(nonatomic) NSPoint dragStartOrigin;
@property(nonatomic) BOOL trackingDrag;
@end

@interface SwingController : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) PassivePanel *seatWindow;
@property(nonatomic, strong) PassivePanel *leftVineWindow;
@property(nonatomic, strong) PassivePanel *rightVineWindow;
@property(nonatomic, strong) PassivePanel *topOrnamentWindow;
@property(nonatomic, strong) VineView *leftVineView;
@property(nonatomic, strong) VineView *rightVineView;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSTimer *orderingTimer;
@property(nonatomic, strong) NSTimer *vineAnimationTimer;
@property(nonatomic) NSTimeInterval vineAnimationStartTime;
@property(nonatomic) BOOL swingVisible;
@property(nonatomic) BOOL draggingSeat;
- (void)moveSeatToOrigin:(NSPoint)origin save:(BOOL)save;
- (void)beginSeatDrag;
- (void)finishSeatDrag;
- (void)centerSwing:(id)sender;
- (void)toggleSwing:(id)sender;
- (void)quitSwing:(id)sender;
@end

@implementation SwingSeatView

- (BOOL)isFlipped { return NO; }
- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }

- (NSBezierPath *)smallLeafAtPoint:(NSPoint)point mirrored:(BOOL)mirrored {
    CGFloat direction = mirrored ? -1.0 : 1.0;
    NSBezierPath *leaf = [NSBezierPath bezierPath];
    [leaf moveToPoint:NSMakePoint(point.x, point.y)];
    [leaf curveToPoint:NSMakePoint(point.x + direction * 11.0, point.y + 3.0)
         controlPoint1:NSMakePoint(point.x + direction * 4.0, point.y + 7.0)
         controlPoint2:NSMakePoint(point.x + direction * 10.0, point.y + 7.0)];
    [leaf curveToPoint:NSMakePoint(point.x, point.y)
         controlPoint1:NSMakePoint(point.x + direction * 8.0, point.y - 1.0)
         controlPoint2:NSMakePoint(point.x + direction * 3.0, point.y - 1.0)];
    [leaf closePath];
    return leaf;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    (void)dirtyRect;

    NSRect bounds = self.bounds;
    CGFloat boardHeight = 25.0;
    NSRect boardRect = NSMakeRect(2.5, NSMaxY(bounds) - boardHeight - 1.0, NSWidth(bounds) - 5.0, boardHeight);

    NSBezierPath *castShadow = [NSBezierPath bezierPathWithRoundedRect:NSOffsetRect(boardRect, 0.0, -5.0)
                                                               xRadius:7.0
                                                               yRadius:7.0];
    [SwingColor(0.10, 0.08, 0.04, 0.30) setFill];
    [castShadow fill];

    NSBezierPath *board = [NSBezierPath bezierPathWithRoundedRect:boardRect xRadius:7.0 yRadius:7.0];
    NSGradient *wood = [[NSGradient alloc]
        initWithColorsAndLocations:
            SwingColor(0.72, 0.49, 0.24, 1.0), 0.0,
            SwingColor(0.49, 0.29, 0.13, 1.0), 0.58,
            SwingColor(0.29, 0.17, 0.08, 1.0), 1.0,
            nil];
    [wood drawInBezierPath:board angle:-90.0];

    [NSGraphicsContext saveGraphicsState];
    [board addClip];
    for (NSInteger index = 0; index < 4; index += 1) {
        CGFloat y = NSMinY(boardRect) + 5.0 + index * 4.4;
        NSBezierPath *grain = [NSBezierPath bezierPath];
        [grain moveToPoint:NSMakePoint(NSMinX(boardRect) + 8.0, y)];
        [grain curveToPoint:NSMakePoint(NSMaxX(boardRect) - 8.0, y + (index % 2 == 0 ? 1.2 : -1.0))
              controlPoint1:NSMakePoint(NSMidX(boardRect) - 42.0, y + 2.2)
              controlPoint2:NSMakePoint(NSMidX(boardRect) + 35.0, y - 2.0)];
        [SwingColor(0.94, 0.70, 0.37, index == 0 ? 0.32 : 0.20) setStroke];
        grain.lineWidth = 0.75;
        [grain stroke];
    }
    [NSGraphicsContext restoreGraphicsState];

    [SwingColor(0.82, 0.67, 0.32, 0.98) setStroke];
    board.lineWidth = 1.45;
    [board stroke];

    NSBezierPath *topHighlight = [NSBezierPath bezierPath];
    [topHighlight moveToPoint:NSMakePoint(NSMinX(boardRect) + 9.0, NSMaxY(boardRect) - 1.0)];
    [topHighlight lineToPoint:NSMakePoint(NSMaxX(boardRect) - 9.0, NSMaxY(boardRect) - 1.0)];
    [SwingColor(1.0, 0.85, 0.52, 0.70) setStroke];
    topHighlight.lineWidth = 1.0;
    [topHighlight stroke];

    for (NSNumber *position in @[@(kLeftAttachmentX), @(kRightAttachmentX)]) {
        CGFloat x = position.doubleValue;
        NSBezierPath *outer = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x - 5.2, NSMaxY(boardRect) - 10.8, 10.4, 10.4)];
        [SwingColor(0.88, 0.74, 0.36, 1.0) setFill];
        [outer fill];
        [SwingColor(0.24, 0.26, 0.13, 0.94) setStroke];
        outer.lineWidth = 1.0;
        [outer stroke];
        NSBezierPath *inner = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x - 2.0, NSMaxY(boardRect) - 7.6, 4.0, 4.0)];
        [SwingColor(0.24, 0.36, 0.20, 1.0) setFill];
        [inner fill];
    }

    CGFloat ornamentY = NSMinY(boardRect) - 1.5;
    NSBezierPath *whiplash = [NSBezierPath bezierPath];
    [whiplash moveToPoint:NSMakePoint(29.0, ornamentY + 4.0)];
    [whiplash curveToPoint:NSMakePoint(NSMidX(bounds), ornamentY - 10.0)
             controlPoint1:NSMakePoint(66.0, ornamentY - 2.0)
             controlPoint2:NSMakePoint(NSMidX(bounds) - 45.0, ornamentY - 10.0)];
    [whiplash curveToPoint:NSMakePoint(NSWidth(bounds) - 29.0, ornamentY + 4.0)
             controlPoint1:NSMakePoint(NSMidX(bounds) + 45.0, ornamentY - 10.0)
             controlPoint2:NSMakePoint(NSWidth(bounds) - 66.0, ornamentY - 2.0)];
    [SwingColor(0.30, 0.40, 0.20, 0.92) setStroke];
    whiplash.lineWidth = 2.1;
    [whiplash stroke];
    NSBezierPath *goldWhiplash = [whiplash copy];
    [SwingColor(0.74, 0.58, 0.25, 0.90) setStroke];
    goldWhiplash.lineWidth = 0.72;
    [goldWhiplash stroke];

    NSBezierPath *leftLeaf = [self smallLeafAtPoint:NSMakePoint(NSMidX(bounds) - 2.0, ornamentY - 9.5) mirrored:YES];
    NSBezierPath *rightLeaf = [self smallLeafAtPoint:NSMakePoint(NSMidX(bounds) + 2.0, ornamentY - 9.5) mirrored:NO];
    [SwingColor(0.39, 0.49, 0.25, 0.96) setFill];
    [leftLeaf fill];
    [rightLeaf fill];
    [SwingColor(0.78, 0.65, 0.30, 0.88) setStroke];
    leftLeaf.lineWidth = 0.65;
    rightLeaf.lineWidth = 0.65;
    [leftLeaf stroke];
    [rightLeaf stroke];

    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:9.5 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: SwingColor(0.32, 0.28, 0.16, 0.62)
    };
    NSString *hint = @"拖动木座移动 · 右键菜单";
    NSSize hintSize = [hint sizeWithAttributes:attributes];
    [hint drawAtPoint:NSMakePoint(NSMidX(bounds) - hintSize.width / 2.0, 7.0)
       withAttributes:attributes];
}

- (void)mouseDown:(NSEvent *)event {
    self.dragStartMouse = [NSEvent mouseLocation];
    self.dragStartOrigin = self.window.frame.origin;
    self.trackingDrag = NO;
    if (event.clickCount == 2) {
        [self.controller centerSwing:nil];
        return;
    }
    self.trackingDrag = YES;
    [self.controller beginSeatDrag];
}

- (void)mouseDragged:(NSEvent *)event {
    if (!self.trackingDrag) return;
    NSPoint current = [NSEvent mouseLocation];
    NSPoint next = NSMakePoint(self.dragStartOrigin.x + current.x - self.dragStartMouse.x,
                               self.dragStartOrigin.y + current.y - self.dragStartMouse.y);
    [self.controller moveSeatToOrigin:next save:NO];
}

- (void)mouseUp:(NSEvent *)event {
    (void)event;
    if (!self.trackingDrag) return;
    self.trackingDrag = NO;
    [self.controller finishSeatDrag];
}

- (void)rightMouseDown:(NSEvent *)event {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"莉莉丝秋千"];

    NSMenuItem *title = [[NSMenuItem alloc] initWithTitle:@"莉莉丝秋千 · 新艺术藤蔓"
                                                   action:nil
                                            keyEquivalent:@""];
    title.enabled = NO;
    [menu addItem:title];
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *center = [[NSMenuItem alloc] initWithTitle:@"移到屏幕中央"
                                                   action:@selector(centerSwing:)
                                            keyEquivalent:@""];
    center.target = self.controller;
    [menu addItem:center];

    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出秋千"
                                                 action:@selector(quitSwing:)
                                          keyEquivalent:@""];
    quit.target = self.controller;
    [menu addItem:quit];

    [NSMenu popUpContextMenu:menu withEvent:event forView:self];
}

@end

@implementation SwingController

- (PassivePanel *)transparentPanelWithFrame:(NSRect)frame {
    PassivePanel *panel = [[PassivePanel alloc]
        initWithContentRect:frame
                  styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                    backing:NSBackingStoreBuffered
                      defer:NO];
    panel.opaque = NO;
    panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = NO;
    panel.hidesOnDeactivate = NO;
    panel.releasedWhenClosed = NO;
    panel.level = NSNormalWindowLevel;
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                               NSWindowCollectionBehaviorFullScreenAuxiliary;
    return panel;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    NSScreen *screen = NSScreen.mainScreen;
    NSRect visibleFrame = screen.visibleFrame;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    CGFloat defaultX = NSMidX(visibleFrame) - kSeatWidth / 2.0;
    CGFloat defaultY = NSMinY(visibleFrame) + NSHeight(visibleFrame) * 0.42;
    CGFloat originX = [defaults objectForKey:kSeatOriginXKey] ? [defaults doubleForKey:kSeatOriginXKey] : defaultX;
    CGFloat originY = [defaults objectForKey:kSeatOriginYKey] ? [defaults doubleForKey:kSeatOriginYKey] : defaultY;

    self.seatWindow = [self transparentPanelWithFrame:NSMakeRect(originX, originY, kSeatWidth, kSeatHeight)];
    self.seatWindow.title = @"Lilith Swing Seat";
    self.seatWindow.accessibilityTitle = @"莉莉丝秋千座板";
    self.seatWindow.movable = NO;

    SwingSeatView *seatView = [[SwingSeatView alloc] initWithFrame:NSMakeRect(0.0, 0.0, kSeatWidth, kSeatHeight)];
    seatView.controller = self;
    self.seatWindow.contentView = seatView;

    self.leftVineWindow = [self transparentPanelWithFrame:NSMakeRect(0.0, 0.0, kVineWidth, 10.0)];
    self.rightVineWindow = [self transparentPanelWithFrame:NSMakeRect(0.0, 0.0, kVineWidth, 10.0)];
    self.leftVineWindow.ignoresMouseEvents = YES;
    self.rightVineWindow.ignoresMouseEvents = YES;
    self.leftVineWindow.title = @"Lilith Swing Vine";
    self.rightVineWindow.title = @"Lilith Swing Vine";

    self.leftVineView = [[VineView alloc] initWithFrame:NSMakeRect(0.0, 0.0, kVineWidth, 10.0)];
    self.rightVineView = [[VineView alloc] initWithFrame:NSMakeRect(0.0, 0.0, kVineWidth, 10.0)];
    self.leftVineView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.rightVineView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.rightVineView.mirrored = YES;
    self.leftVineWindow.contentView = self.leftVineView;
    self.rightVineWindow.contentView = self.rightVineView;

    self.topOrnamentWindow = [self transparentPanelWithFrame:NSMakeRect(0.0, 0.0, kSeatWidth, kTopOrnamentHeight)];
    self.topOrnamentWindow.ignoresMouseEvents = YES;
    self.topOrnamentWindow.title = @"Lilith Swing Top Ornament";
    TopOrnamentView *ornament = [[TopOrnamentView alloc] initWithFrame:NSMakeRect(0.0, 0.0, kSeatWidth, kTopOrnamentHeight)];
    ornament.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.topOrnamentWindow.contentView = ornament;

    [self moveSeatToOrigin:NSMakePoint(originX, originY) save:NO];
    [self setupStatusItem];
    [self showSwing];

    self.orderingTimer = [NSTimer scheduledTimerWithTimeInterval:0.8
                                                          target:self
                                                        selector:@selector(refreshWindowOrder:)
                                                        userInfo:nil
                                                         repeats:YES];
}

- (void)setupStatusItem {
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"❧";
    self.statusItem.button.toolTip = @"莉莉丝秋千";

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"莉莉丝秋千"];
    NSMenuItem *toggle = [[NSMenuItem alloc] initWithTitle:@"隐藏秋千"
                                                   action:@selector(toggleSwing:)
                                            keyEquivalent:@""];
    toggle.target = self;
    toggle.tag = 1001;
    [menu addItem:toggle];

    NSMenuItem *center = [[NSMenuItem alloc] initWithTitle:@"移到屏幕中央"
                                                   action:@selector(centerSwing:)
                                            keyEquivalent:@""];
    center.target = self;
    [menu addItem:center];
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出莉莉丝秋千"
                                                 action:@selector(quitSwing:)
                                          keyEquivalent:@"q"];
    quit.target = self;
    [menu addItem:quit];
    self.statusItem.menu = menu;
}

- (void)layoutSupportWindows {
    NSRect seatFrame = self.seatWindow.frame;
    NSScreen *screen = NSScreen.mainScreen;
    CGFloat screenTop = NSMaxY(screen.frame);
    CGFloat ropeBottom = NSMaxY(seatFrame) - 2.0;
    CGFloat vineHeight = MAX(3.0, screenTop - ropeBottom);

    CGFloat leftCenterX = NSMinX(seatFrame) + kLeftAttachmentX;
    CGFloat rightCenterX = NSMinX(seatFrame) + kRightAttachmentX;
    NSRect leftFrame = NSMakeRect(leftCenterX - kVineWidth / 2.0,
                                  ropeBottom,
                                  kVineWidth,
                                  vineHeight);
    NSRect rightFrame = NSMakeRect(rightCenterX - kVineWidth / 2.0,
                                   ropeBottom,
                                   kVineWidth,
                                   vineHeight);
    [self.leftVineWindow setFrame:leftFrame display:YES];
    [self.rightVineWindow setFrame:rightFrame display:YES];

    NSRect ornamentFrame = NSMakeRect(NSMinX(seatFrame),
                                      screenTop - kTopOrnamentHeight,
                                      kSeatWidth,
                                      kTopOrnamentHeight);
    [self.topOrnamentWindow setFrame:ornamentFrame display:YES];
}

- (void)setVineRevealProgress:(CGFloat)progress {
    self.leftVineView.revealProgress = progress;
    self.rightVineView.revealProgress = progress;
    [self.leftVineView setNeedsDisplay:YES];
    [self.rightVineView setNeedsDisplay:YES];
}

- (void)startVineReveal {
    [self.vineAnimationTimer invalidate];
    self.vineAnimationTimer = nil;
    if (!self.swingVisible || self.draggingSeat) return;

    [self layoutSupportWindows];
    [self setVineRevealProgress:0.0];
    [self.leftVineWindow orderFrontRegardless];
    [self.rightVineWindow orderFrontRegardless];
    [self.topOrnamentWindow orderFrontRegardless];
    [self.seatWindow orderFrontRegardless];

    self.vineAnimationStartTime = NSDate.timeIntervalSinceReferenceDate;
    self.vineAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                                                               target:self
                                                             selector:@selector(animateVines:)
                                                             userInfo:nil
                                                              repeats:YES];
    self.vineAnimationTimer.tolerance = 1.0 / 180.0;
}

- (void)animateVines:(NSTimer *)timer {
    NSTimeInterval elapsed = NSDate.timeIntervalSinceReferenceDate - self.vineAnimationStartTime;
    CGFloat linear = MIN(1.0, MAX(0.0, elapsed / kVineRevealDuration));
    CGFloat eased = 1.0 - pow(1.0 - linear, 3.0);
    [self setVineRevealProgress:eased];
    if (linear >= 1.0) {
        [timer invalidate];
        self.vineAnimationTimer = nil;
    }
}

- (void)showSwing {
    self.swingVisible = YES;
    [self.seatWindow orderFrontRegardless];
    [self updateToggleMenuTitle];
    [self startVineReveal];
}

- (void)hideSwing {
    self.swingVisible = NO;
    [self.vineAnimationTimer invalidate];
    self.vineAnimationTimer = nil;
    [self.topOrnamentWindow orderOut:nil];
    [self.leftVineWindow orderOut:nil];
    [self.rightVineWindow orderOut:nil];
    [self.seatWindow orderOut:nil];
    [self updateToggleMenuTitle];
}

- (void)updateToggleMenuTitle {
    NSMenuItem *toggle = [self.statusItem.menu itemWithTag:1001];
    toggle.title = self.swingVisible ? @"隐藏秋千" : @"显示秋千";
}

- (void)refreshWindowOrder:(NSTimer *)timer {
    (void)timer;
    if (!self.swingVisible) return;
    [self.seatWindow orderFrontRegardless];
    if (self.draggingSeat) return;
    [self.leftVineWindow orderFrontRegardless];
    [self.rightVineWindow orderFrontRegardless];
    [self.topOrnamentWindow orderFrontRegardless];
    [self.seatWindow orderFrontRegardless];
}

- (void)moveSeatToOrigin:(NSPoint)origin save:(BOOL)save {
    NSScreen *screen = NSScreen.mainScreen;
    NSRect visible = screen.visibleFrame;
    origin.x = MAX(NSMinX(visible), MIN(origin.x, NSMaxX(visible) - kSeatWidth));
    origin.y = MAX(NSMinY(visible) + 10.0, MIN(origin.y, NSMaxY(visible) - kSeatHeight - 8.0));
    [self.seatWindow setFrameOrigin:origin];

    if (!self.draggingSeat) [self layoutSupportWindows];

    if (save) {
        [NSUserDefaults.standardUserDefaults setDouble:origin.x forKey:kSeatOriginXKey];
        [NSUserDefaults.standardUserDefaults setDouble:origin.y forKey:kSeatOriginYKey];
    }
}

- (void)beginSeatDrag {
    if (!self.swingVisible || self.draggingSeat) return;
    self.draggingSeat = YES;
    [self.vineAnimationTimer invalidate];
    self.vineAnimationTimer = nil;
    [self.topOrnamentWindow orderOut:nil];
    [self.leftVineWindow orderOut:nil];
    [self.rightVineWindow orderOut:nil];
    [self.seatWindow orderFrontRegardless];
}

- (void)finishSeatDrag {
    if (!self.draggingSeat) return;
    self.draggingSeat = NO;
    [self moveSeatToOrigin:self.seatWindow.frame.origin save:YES];
    [self startVineReveal];
}

- (void)centerSwing:(id)sender {
    (void)sender;
    NSRect visible = NSScreen.mainScreen.visibleFrame;
    NSPoint origin = NSMakePoint(NSMidX(visible) - kSeatWidth / 2.0,
                                 NSMinY(visible) + NSHeight(visible) * 0.42);
    self.draggingSeat = NO;
    [self moveSeatToOrigin:origin save:YES];
    if (!self.swingVisible) {
        [self showSwing];
    } else {
        [self startVineReveal];
    }
}

- (void)toggleSwing:(id)sender {
    (void)sender;
    self.swingVisible ? [self hideSwing] : [self showSwing];
}

- (void)quitSwing:(id)sender {
    (void)sender;
    [NSApp terminate:nil];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    (void)sender;
    (void)flag;
    [self showSwing];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    [self.vineAnimationTimer invalidate];
    [self.orderingTimer invalidate];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        (void)argc;
        (void)argv;
        NSApplication *application = NSApplication.sharedApplication;
        SwingController *controller = [[SwingController alloc] init];
        application.delegate = controller;
        [application run];
    }
    return 0;
}
