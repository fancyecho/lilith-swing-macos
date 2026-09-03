#import "SwingWindowPolicy.h"
#import <dlfcn.h>

typedef int (*SwingMainConnectionFunction)(void);
typedef CGError (*SwingSetSublevelFunction)(int, uint32_t, int);

BOOL SwingSetCompatibleTopmost(NSWindow *window, BOOL enabled) {
    static SwingMainConnectionFunction mainConnection;
    static SwingSetSublevelFunction setSublevel;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // Optional private API, also used by open-source macOS window tools.
        // No injection, privileged connection or change to other apps is used.
        // Keep this handle for the lifetime of the resolved function pointers.
        void *library = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
                               RTLD_LAZY | RTLD_LOCAL);
        if (library) {
            mainConnection = (SwingMainConnectionFunction)dlsym(library, "SLSMainConnectionID");
            setSublevel = (SwingSetSublevelFunction)dlsym(library, "SLSSetWindowSubLevel");
        }
    });
    if (!window || window.windowNumber <= 0) return NO;
    if (!mainConnection || !setSublevel) return !enabled;
    // Sublevel 1 is above ordinary windows, while the exported layer remains
    // 0 and Lilith's floating layer 3 remains above the artwork.
    return setSublevel(mainConnection(), (uint32_t)window.windowNumber, enabled ? 1 : 0)
        == kCGErrorSuccess;
}
