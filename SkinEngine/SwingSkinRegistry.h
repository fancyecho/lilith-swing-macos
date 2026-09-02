#import "SwingSkin.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwingSkinRegistry : NSObject

+ (NSArray<id<SwingSkin>> *)availableSkins;
+ (id<SwingSkin>)skinWithIdentifier:(NSString *)identifier;
+ (id<SwingSkin>)defaultSkin;

@end

NS_ASSUME_NONNULL_END
