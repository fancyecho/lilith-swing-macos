#import "SwingSkin.h"

@interface SwingSkinAssetCatalog ()
@property(nonatomic, readwrite, copy) NSURL *rootURL;
@property(nonatomic, readwrite, copy) NSDictionary *manifest;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSImage *> *imageCache;
@end

@implementation SwingSkinAssetCatalog

- (instancetype)initWithRootURL:(NSURL *)rootURL error:(NSError **)error {
    self = [super init];
    if (!self) return nil;

    NSURL *manifestURL = [rootURL URLByAppendingPathComponent:@"skin.json"];
    NSData *data = [NSData dataWithContentsOfURL:manifestURL options:0 error:error];
    if (!data) return nil;

    id decoded = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![decoded isKindOfClass:NSDictionary.class]) return nil;

    self.rootURL = rootURL;
    self.manifest = decoded;
    self.imageCache = [NSMutableDictionary dictionary];
    return self;
}

- (NSString *)stringForKey:(NSString *)key fallback:(NSString *)fallback {
    id value = self.manifest[key];
    return [value isKindOfClass:NSString.class] ? value : fallback;
}

- (CGFloat)metricForKey:(NSString *)key fallback:(CGFloat)fallback {
    NSDictionary *metrics = self.manifest[@"metrics"];
    id value = [metrics isKindOfClass:NSDictionary.class] ? metrics[key] : nil;
    return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : fallback;
}

- (NSDictionary *)assetEntryNamed:(NSString *)name {
    NSDictionary *assets = self.manifest[@"assets"];
    id entry = [assets isKindOfClass:NSDictionary.class] ? assets[name] : nil;
    return [entry isKindOfClass:NSDictionary.class] ? entry : @{};
}

- (NSImage *)imageNamed:(NSString *)name {
    NSImage *cached = self.imageCache[name];
    if (cached) return cached;

    NSDictionary *entry = [self assetEntryNamed:name];
    NSString *relativePath = entry[@"file"];
    if (![relativePath isKindOfClass:NSString.class]) return nil;

    NSURL *imageURL = [self.rootURL URLByAppendingPathComponent:relativePath];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:imageURL];
    if (image) self.imageCache[name] = image;
    return image;
}

- (NSRect)sourceRectForAssetNamed:(NSString *)name {
    NSDictionary *entry = [self assetEntryNamed:name];
    NSArray *values = entry[@"sourceRect"];
    if (![values isKindOfClass:NSArray.class] || values.count != 4) return NSZeroRect;
    return NSMakeRect([values[0] doubleValue],
                      [values[1] doubleValue],
                      [values[2] doubleValue],
                      [values[3] doubleValue]);
}

@end
