#import <Foundation/Foundation.h>


@interface EditionSet : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *editionSetID;

@property (nonatomic, copy, readonly) NSString *dimensionsInches;
@property (nonatomic, copy, readonly) NSString *dimensionsCM;
@property (nonatomic, copy, readonly) NSString *editions;
@property (nonatomic, copy, readonly) NSString *availability;
@property (nonatomic, copy, readonly) NSString *saleMessage;


@end
