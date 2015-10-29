#import "EditionSet.h"


@implementation EditionSet

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @keypath(EditionSet.new, editionSetID) : @"id",
        @keypath(EditionSet.new, dimensionsCM) : @"dimensions.cm",
        @keypath(EditionSet.new, dimensionsInches) : @"dimensions.in",
    };
}

@end
