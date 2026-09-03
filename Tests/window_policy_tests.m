// Compile the actual app's window factory without launching its event loop.
#define main LilithSwingApplicationMain
#import "../main.m"
#undef main
#import "../Skins/Mucha/MuchaSkin.h"

static void Require(BOOL condition, NSString *message) {
    if (condition) return;
    fprintf(stderr, "FAIL: %s\n", message.UTF8String);
    exit(1);
}

static void CheckSupportGeometry(void) {
    NSRect screen = NSMakeRect(0, 0, 1470, 956);
    for (NSNumber *height in @[@40, @274, @640]) {
        NSRect artwork = NSMakeRect(1198, height.doubleValue, 248, 104);
        NSRect support = SwingSupportFrameForSeat(artwork, screen);
        Require(NSMaxY(support) == NSMaxY(artwork) && NSMinX(support) == NSMinX(artwork) &&
                NSWidth(support) == NSWidth(artwork), @"Never move the seating edge or widen it");
        Require(NSMinY(support) == NSMinY(screen), @"Support must reach the display floor");
        CGFloat seatedY = NSMaxY(artwork) - 158.7;
        if (seatedY >= NSMinY(screen)) {
            Require(NSPointInRect(NSMakePoint(NSMidX(artwork), seatedY), support),
                    @"The previously unsupported seated root must now lie in the support");
        }
    }
    NSRect offset = SwingSupportFrameForSeat(NSMakeRect(-300, 180, 248, 104),
                                             NSMakeRect(-1470, -100, 1470, 956));
    Require(NSMinY(offset) == -100 && NSMaxY(offset) == 284,
            @"Geometry must respect a nonzero display origin");
    printf("PASS: unchanged top/width and seated-position coverage at several heights\n");
}

static void CheckSupportPolicy(void) {
    SwingController *controller = [[SwingController alloc] init];
    controller.compatibleTopmost = YES;
    NSString *root = NSProcessInfo.processInfo.environment[@"LILITH_SWING_TEST_RESOURCE_ROOT"];
    Require(root.length > 0, @"Skin fixture path must be supplied by test.zsh");
    controller.skin = [[MuchaSkin alloc] initWithResourceRoot:[NSURL fileURLWithPath:root] error:nil];
    Require(controller.skin != nil, @"Load the actual skin without changing it");
    NSRect artworkFrame = NSMakeRect(1198, 274, 248, 104);
    controller.seatWindow = [controller transparentPanelWithFrame:artworkFrame];
    controller.seatSupportWindow = [controller seatSupportPanelForSeatFrame:artworkFrame];
    [controller applySeatSupportPolicy];
    Require(controller.seatSupportWindow.ignoresMouseEvents, @"Extended area must always pass input through");
    Require(!controller.seatWindow.ignoresMouseEvents, @"Original artwork remains draggable");
    Require(NSEqualRects(controller.seatWindow.frame, artworkFrame), @"Artwork size and placement must not change");
    Require(controller.seatSupportWindow.level == NSNormalWindowLevel, @"Game-facing support stays at level 0");
    if (controller.extendedSupportActive) {
        Require(controller.seatWindow.level > NSNormalWindowLevel &&
                controller.seatWindow.level < NSFloatingWindowLevel,
                @"Artwork must not become a duplicate game surface or cover Lilith");
    }
    Require(!controller.seatSupportWindow.visible, @"Changing policy must not show a hidden swing");
    NSInteger supportID = controller.seatSupportWindow.windowNumber;
    controller.draggingSeat = YES;
    [controller moveSeatToOrigin:NSMakePoint(1100, 400) save:NO];
    Require(NSEqualRects(controller.seatSupportWindow.frame,
                        SwingSupportFrameForSeat(controller.seatWindow.frame, NSScreen.mainScreen.frame)),
            @"Support must follow even while the decorative vines are hidden during dragging");
    Require(controller.seatSupportWindow.windowNumber == supportID, @"Movement must preserve support identity");
    controller.compatibleTopmost = NO;
    [controller applySeatSupportPolicy];
    Require(!controller.extendedSupportActive && !controller.seatSupportWindow.visible &&
            controller.seatWindow.level == NSNormalWindowLevel, @"Disabled mode restores one short ordinary seat");
    [controller.seatSupportWindow close];
    [controller.seatWindow close];
    printf("PASS: mouse pass-through, original artwork, unique game surface, drag sync and fallback\n");
}

static void CheckWindowServerOrder(SwingController *controller) {
    // Tiny transparent test surfaces stay below Lilith's minimum size and
    // never receive focus or mouse input. No external window is manipulated.
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSApp finishLaunching];
    PassivePanel *pinned = [controller seatSupportPanelForSeatFrame:NSMakeRect(5, 30, 20, 20)];
    PassivePanel *artwork = [controller transparentPanelWithFrame:NSMakeRect(5, 30, 20, 20)];
    artwork.level = NSNormalWindowLevel + 1;
    PassivePanel *normal = [controller transparentPanelWithFrame:NSMakeRect(5, 30, 20, 20)];
    PassivePanel *pet = [controller transparentPanelWithFrame:NSMakeRect(5, 30, 20, 20)];
    normal.compatibleTopmost = NO;
    pet.compatibleTopmost = NO;
    pet.level = NSFloatingWindowLevel;
    for (PassivePanel *window in @[pinned, artwork, normal, pet]) {
        window.ignoresMouseEvents = YES;
        [window orderFrontRegardless];
    }
    Require(pinned.topmostApplied, @"This system must support the optional sublevel adapter");
    for (int attempt = 0; attempt < 30; attempt++) {
        [normal orderFrontRegardless];
        if (attempt == 10) {
            [pinned orderOut:nil];
            [pinned orderFrontRegardless];
        }
        if (attempt == 20) [pinned setFrameOrigin:NSMakePoint(8, 30)];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        NSArray *windows = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, 0));
        NSInteger pinnedIndex = NSNotFound, normalIndex = NSNotFound, petIndex = NSNotFound;
        NSInteger artworkIndex = NSNotFound;
        for (NSUInteger index = 0; index < windows.count; index++) {
            NSDictionary *entry = windows[index];
            NSInteger number = [entry[(id)kCGWindowNumber] integerValue];
            if (number == pinned.windowNumber) {
                pinnedIndex = index;
                Require([entry[(id)kCGWindowLayer] integerValue] == NSNormalWindowLevel,
                        @"WindowServer must expose layer 0 to the game");
            }
            if (number == normal.windowNumber) normalIndex = index;
            if (number == pet.windowNumber) petIndex = index;
            if (number == artwork.windowNumber) {
                artworkIndex = index;
                Require([entry[(id)kCGWindowLayer] integerValue] == 1, @"Artwork is excluded from the game's layer-0 scan");
            }
        }
        Require(pinnedIndex != NSNotFound && normalIndex != NSNotFound && petIndex != NSNotFound,
                @"All test windows must be visible to WindowServer");
        Require(artworkIndex != NSNotFound && petIndex < artworkIndex &&
                artworkIndex < pinnedIndex && pinnedIndex < normalIndex,
                @"Floating pet > artwork > support > repeatedly raised normal window");
    }
    for (NSWindow *window in @[pinned, artwork, normal, pet]) [window close];
    printf("PASS: 30 real WindowServer order checks, including hide/show and movement\n");
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        CheckSupportGeometry();
        CheckSupportPolicy();
        SwingController *controller = [[SwingController alloc] init];
        controller.compatibleTopmost = YES;
        PassivePanel *panel = [controller transparentPanelWithFrame:NSMakeRect(100, 100, 248, 104)];
        Require(panel.level == NSNormalWindowLevel, @"Lilith must still see an ordinary window");
        Require(panel.compatibleTopmost, @"Compatible topmost preference must reach the panel");
        Require(panel.level < NSFloatingWindowLevel, @"Swing must stay below Lilith's floating window");
        Require(!panel.canBecomeKeyWindow && !panel.canBecomeMainWindow, @"Swing must not steal focus");
        Require((panel.styleMask & NSWindowStyleMaskNonactivatingPanel) != 0, @"Keep non-activating panel behavior");
        Require(!panel.hidesOnDeactivate, @"Swing must remain visible when another app becomes active");
        Require(!panel.opaque && !panel.hasShadow, @"Keep transparent window rendering");
        Require((panel.collectionBehavior & NSWindowCollectionBehaviorCanJoinAllSpaces) != 0,
                @"Keep all-Spaces visibility");
        Require(![controller respondsToSelector:NSSelectorFromString(@"refreshWindowOrder:")],
                @"Do not reintroduce periodic reordering");
        Require(![controller respondsToSelector:NSSelectorFromString(@"orderingTimer")],
                @"Do not reintroduce the ordering timer");
        panel.compatibleTopmost = NO;
        Require(!panel.compatibleTopmost && panel.level == NSNormalWindowLevel,
                @"Topmost must be reversible without changing the game-visible level");
        Require(!SwingSetCompatibleTopmost(nil, YES), @"Reject missing window safely");
        [panel close];
        printf("PASS: stable level, focus, visibility, transparency, Spaces and no reorder timer\n");
        if (argc > 1 && strcmp(argv[1], "--window-server") == 0) CheckWindowServerOrder(controller);
    }
    return 0;
}
