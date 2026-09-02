#import <AppKit/AppKit.h>
#import <math.h>
#import "SkinEngine/SwingSkin.h"
#import "SkinEngine/SwingSkinRegistry.h"

static const NSTimeInterval kVineRevealDuration = 0.62;
static NSString *const kSeatOriginXKey = @"seatOriginX";
static NSString *const kSeatOriginYKey = @"seatOriginY";
static NSString *const kSelectedSkinKey = @"selectedSkinIdentifier";

@class SwingController;

@interface PassivePanel : NSPanel
@end

@implementation PassivePanel
- (BOOL)canBecomeKeyWindow { return NO; }
- (BOOL)canBecomeMainWindow { return NO; }
@end

@interface VineView : NSView
@property(nonatomic, strong) id<SwingSkin> skin;
@property(nonatomic) BOOL mirrored;
@property(nonatomic) CGFloat revealProgress;
@end

@implementation VineView
- (BOOL)isFlipped { return NO; }
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    (void)dirtyRect;
    [self.skin drawVineInRect:self.bounds
                    mirrored:self.mirrored
              revealProgress:self.revealProgress];
}
@end

@interface TopOrnamentView : NSView
@property(nonatomic, strong) id<SwingSkin> skin;
@end

@implementation TopOrnamentView
- (BOOL)isFlipped { return NO; }
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    (void)dirtyRect;
    [self.skin drawTopOrnamentInRect:self.bounds];
}
@end

@interface SwingSeatView : NSView
@property(nonatomic, weak) SwingController *controller;
@property(nonatomic, strong) id<SwingSkin> skin;
@property(nonatomic) NSPoint dragStartMouse;
@property(nonatomic) NSPoint dragStartOrigin;
@property(nonatomic) BOOL trackingDrag;
@end

@interface SwingController : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) id<SwingSkin> skin;
@property(nonatomic, strong) PassivePanel *seatWindow;
@property(nonatomic, strong) PassivePanel *leftVineWindow;
@property(nonatomic, strong) PassivePanel *rightVineWindow;
@property(nonatomic, strong) PassivePanel *topOrnamentWindow;
@property(nonatomic, strong) SwingSeatView *seatView;
@property(nonatomic, strong) VineView *leftVineView;
@property(nonatomic, strong) VineView *rightVineView;
@property(nonatomic, strong) TopOrnamentView *topOrnamentView;
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenu *skinMenu;
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
- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    (void)event;
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    (void)dirtyRect;
    [self.skin drawSeatInRect:self.bounds];
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
    (void)event;
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
    NSString *titleText = [NSString stringWithFormat:@"皮肤：%@", self.skin.displayName];
    NSMenuItem *title = [[NSMenuItem alloc] initWithTitle:titleText action:nil keyEquivalent:@""];
    title.enabled = NO;
    [menu addItem:title];
    [menu addItem:NSMenuItem.separatorItem];

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

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *savedSkinIdentifier = [defaults stringForKey:kSelectedSkinKey];
    self.skin = savedSkinIdentifier.length > 0
        ? [SwingSkinRegistry skinWithIdentifier:savedSkinIdentifier]
        : SwingSkinRegistry.defaultSkin;

    NSSize seatSize = self.skin.seatWindowSize;
    NSRect visibleFrame = NSScreen.mainScreen.visibleFrame;
    CGFloat defaultX = NSMidX(visibleFrame) - seatSize.width / 2.0;
    CGFloat defaultY = NSMinY(visibleFrame) + NSHeight(visibleFrame) * 0.42;
    CGFloat originX = [defaults objectForKey:kSeatOriginXKey]
        ? [defaults doubleForKey:kSeatOriginXKey]
        : defaultX;
    CGFloat originY = [defaults objectForKey:kSeatOriginYKey]
        ? [defaults doubleForKey:kSeatOriginYKey]
        : defaultY;

    self.seatWindow = [self transparentPanelWithFrame:NSMakeRect(originX,
                                                                  originY,
                                                                  seatSize.width,
                                                                  seatSize.height)];
    self.seatWindow.title = @"Lilith Swing Seat";
    self.seatWindow.accessibilityTitle = @"莉莉丝秋千座板";
    self.seatWindow.movable = NO;

    self.seatView = [[SwingSeatView alloc] initWithFrame:NSMakeRect(0.0, 0.0, seatSize.width, seatSize.height)];
    self.seatView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.seatView.controller = self;
    self.seatView.skin = self.skin;
    self.seatWindow.contentView = self.seatView;

    CGFloat vineWidth = self.skin.vineWindowWidth;
    self.leftVineWindow = [self transparentPanelWithFrame:NSMakeRect(0.0, 0.0, vineWidth, 10.0)];
    self.rightVineWindow = [self transparentPanelWithFrame:NSMakeRect(0.0, 0.0, vineWidth, 10.0)];
    self.leftVineWindow.ignoresMouseEvents = YES;
    self.rightVineWindow.ignoresMouseEvents = YES;
    self.leftVineWindow.accessibilityElement = NO;
    self.rightVineWindow.accessibilityElement = NO;
    self.leftVineWindow.title = @"Lilith Swing Vine";
    self.rightVineWindow.title = @"Lilith Swing Vine";

    self.leftVineView = [[VineView alloc] initWithFrame:NSMakeRect(0.0, 0.0, vineWidth, 10.0)];
    self.rightVineView = [[VineView alloc] initWithFrame:NSMakeRect(0.0, 0.0, vineWidth, 10.0)];
    self.leftVineView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.rightVineView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.leftVineView.skin = self.skin;
    self.rightVineView.skin = self.skin;
    self.rightVineView.mirrored = YES;
    self.leftVineWindow.contentView = self.leftVineView;
    self.rightVineWindow.contentView = self.rightVineView;

    CGFloat ornamentHeight = self.skin.topOrnamentHeight;
    self.topOrnamentWindow = [self transparentPanelWithFrame:NSMakeRect(0.0,
                                                                        0.0,
                                                                        seatSize.width,
                                                                        ornamentHeight)];
    self.topOrnamentWindow.ignoresMouseEvents = YES;
    self.topOrnamentWindow.accessibilityElement = NO;
    self.topOrnamentWindow.title = @"Lilith Swing Top Ornament";
    self.topOrnamentView = [[TopOrnamentView alloc] initWithFrame:NSMakeRect(0.0,
                                                                             0.0,
                                                                             seatSize.width,
                                                                             ornamentHeight)];
    self.topOrnamentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.topOrnamentView.skin = self.skin;
    self.topOrnamentWindow.contentView = self.topOrnamentView;

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

    self.skinMenu = [[NSMenu alloc] initWithTitle:@"皮肤"];
    NSMenuItem *skinRoot = [[NSMenuItem alloc] initWithTitle:@"皮肤" action:nil keyEquivalent:@""];
    skinRoot.submenu = self.skinMenu;
    [menu addItem:skinRoot];
    [self rebuildSkinMenu];

    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出莉莉丝秋千"
                                                 action:@selector(quitSwing:)
                                          keyEquivalent:@"q"];
    quit.target = self;
    [menu addItem:quit];
    self.statusItem.menu = menu;
}

- (void)rebuildSkinMenu {
    [self.skinMenu removeAllItems];
    for (id<SwingSkin> availableSkin in SwingSkinRegistry.availableSkins) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:availableSkin.displayName
                                                     action:@selector(selectSkin:)
                                              keyEquivalent:@""];
        item.target = self;
        item.representedObject = availableSkin.identifier;
        item.state = [availableSkin.identifier isEqualToString:self.skin.identifier]
            ? NSControlStateValueOn
            : NSControlStateValueOff;
        [self.skinMenu addItem:item];
    }
}

- (void)selectSkin:(NSMenuItem *)sender {
    NSString *identifier = sender.representedObject;
    id<SwingSkin> selected = [SwingSkinRegistry skinWithIdentifier:identifier];
    if ([selected.identifier isEqualToString:self.skin.identifier]) return;

    NSPoint origin = self.seatWindow.frame.origin;
    self.skin = selected;
    self.seatView.skin = selected;
    self.leftVineView.skin = selected;
    self.rightVineView.skin = selected;
    self.topOrnamentView.skin = selected;

    NSSize seatSize = selected.seatWindowSize;
    [self.seatWindow setFrame:NSMakeRect(origin.x, origin.y, seatSize.width, seatSize.height) display:YES];
    [self moveSeatToOrigin:origin save:YES];
    [NSUserDefaults.standardUserDefaults setObject:selected.identifier forKey:kSelectedSkinKey];

    [self.seatView setNeedsDisplay:YES];
    [self.topOrnamentView setNeedsDisplay:YES];
    [self rebuildSkinMenu];
    [self startVineReveal];
}

- (void)layoutSupportWindows {
    NSRect seatFrame = self.seatWindow.frame;
    CGFloat screenTop = NSMaxY(NSScreen.mainScreen.frame);
    CGFloat vineBottom = NSMaxY(seatFrame) - 2.0;
    CGFloat vineHeight = MAX(3.0, screenTop - vineBottom);
    CGFloat vineWidth = self.skin.vineWindowWidth;

    CGFloat leftCenterX = NSMinX(seatFrame) + self.skin.leftAttachmentX;
    CGFloat rightCenterX = NSMinX(seatFrame) + self.skin.rightAttachmentX;
    [self.leftVineWindow setFrame:NSMakeRect(leftCenterX - vineWidth / 2.0,
                                             vineBottom,
                                             vineWidth,
                                             vineHeight)
                          display:YES];
    [self.rightVineWindow setFrame:NSMakeRect(rightCenterX - vineWidth / 2.0,
                                              vineBottom,
                                              vineWidth,
                                              vineHeight)
                           display:YES];

    [self.topOrnamentWindow setFrame:NSMakeRect(NSMinX(seatFrame),
                                                 screenTop - self.skin.topOrnamentHeight,
                                                 self.skin.seatWindowSize.width,
                                                 self.skin.topOrnamentHeight)
                              display:YES];
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
    NSRect visible = NSScreen.mainScreen.visibleFrame;
    NSSize seatSize = self.skin.seatWindowSize;
    origin.x = MAX(NSMinX(visible), MIN(origin.x, NSMaxX(visible) - seatSize.width));
    origin.y = MAX(NSMinY(visible) + 10.0, MIN(origin.y, NSMaxY(visible) - seatSize.height - 8.0));
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
    NSSize seatSize = self.skin.seatWindowSize;
    NSPoint origin = NSMakePoint(NSMidX(visible) - seatSize.width / 2.0,
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
