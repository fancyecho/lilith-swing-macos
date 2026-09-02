#import "SkinEngine/SwingSkin.h"

NS_ASSUME_NONNULL_BEGIN

@interface MuchaSkin : NSObject <SwingSkin>

- (nullable instancetype)initWithResourceRoot:(NSURL *)resourceRoot
                                        error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
