#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwingSkin <NSObject>

@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic, readonly, copy) NSString *displayName;
@property(nonatomic, readonly) NSSize seatWindowSize;
@property(nonatomic, readonly) CGFloat vineWindowWidth;
@property(nonatomic, readonly) CGFloat topOrnamentHeight;
@property(nonatomic, readonly) CGFloat leftAttachmentX;
@property(nonatomic, readonly) CGFloat rightAttachmentX;

- (void)drawSeatInRect:(NSRect)rect;
- (void)drawVineInRect:(NSRect)rect
              mirrored:(BOOL)mirrored
        revealProgress:(CGFloat)revealProgress;
- (void)drawTopOrnamentInRect:(NSRect)rect;

@end

@interface SwingSkinAssetCatalog : NSObject

@property(nonatomic, readonly, copy) NSURL *rootURL;
@property(nonatomic, readonly, copy) NSDictionary *manifest;

- (nullable instancetype)initWithRootURL:(NSURL *)rootURL
                                   error:(NSError **)error;
- (NSString *)stringForKey:(NSString *)key fallback:(NSString *)fallback;
- (CGFloat)metricForKey:(NSString *)key fallback:(CGFloat)fallback;
- (nullable NSImage *)imageNamed:(NSString *)name;
- (NSRect)sourceRectForAssetNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
