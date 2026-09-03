#import <AppKit/AppKit.h>

// Only changes a window owned by this application. The public window level
// stays normal because Lilith excludes non-normal windows from its surfaces.
BOOL SwingSetCompatibleTopmost(NSWindow *window, BOOL enabled);
