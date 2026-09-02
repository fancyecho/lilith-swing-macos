#import "SwingSkinRegistry.h"
#import "Skins/Mucha/MuchaSkin.h"

@implementation SwingSkinRegistry

+ (NSURL *)resourceRootForSkinFolder:(NSString *)folder {
    NSURL *skinsRoot = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"Skins"];
    return [skinsRoot URLByAppendingPathComponent:folder];
}

+ (NSArray<id<SwingSkin>> *)availableSkins {
    NSError *error = nil;
    MuchaSkin *mucha = [[MuchaSkin alloc] initWithResourceRoot:[self resourceRootForSkinFolder:@"Mucha"]
                                                        error:&error];
    if (!mucha) {
        NSLog(@"Unable to load Mucha skin: %@", error);
        return @[];
    }
    return @[mucha];
}

+ (id<SwingSkin>)skinWithIdentifier:(NSString *)identifier {
    for (id<SwingSkin> skin in self.availableSkins) {
        if ([skin.identifier isEqualToString:identifier]) return skin;
    }
    return self.defaultSkin;
}

+ (id<SwingSkin>)defaultSkin {
    NSArray<id<SwingSkin>> *skins = self.availableSkins;
    NSAssert(skins.count > 0, @"At least one swing skin must be bundled.");
    return skins.firstObject;
}

@end
