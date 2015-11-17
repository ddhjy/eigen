#import "ARStandardDateFormatter.h"
#import "NSDate+DateRange.h"

static ARStandardDateFormatter *staticDateFormatter;


@interface PartnerShow ()
@property (nonatomic, copy, readonly) NSString *imageAddress;
@property (nonatomic, copy, readonly) NSArray *imageVersions;
@end


@implementation PartnerShow

- (id)initWithShowID:(NSString *)showID
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _showID = showID;

    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @keypath(PartnerShow.new, showID) : @"id",
        @keypath(PartnerShow.new, partner) : @"partner",
        @keypath(PartnerShow.new, artworks) : @"artworks",
        @keypath(PartnerShow.new, artists) : @"artists",
        @keypath(PartnerShow.new, fair) : @"fair",
        @keypath(PartnerShow.new, installationShots) : @"installation_shots",
        @keypath(PartnerShow.new, posts) : @"posts",
        @keypath(PartnerShow.new, name) : @"name",
        @keypath(PartnerShow.new, startDate) : @"start_at",
        @keypath(PartnerShow.new, endDate) : @"end_at",
        @keypath(PartnerShow.new, imageAddress) : @"image_url",
        @keypath(PartnerShow.new, imageVersions) : @"image_versions",
        @keypath(PartnerShow.new, location) : @"location",
        @keypath(PartnerShow.new, locationInFair) : @"fair_location.display",
        @keypath(PartnerShow.new, fairLocation) : @"fair_location",
        @keypath(PartnerShow.new, officialDescription) : @"description",
    };
}

+ (NSValueTransformer *)fairJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[Fair class]];
}

+ (NSValueTransformer *)artworksJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[Artwork class]];
}

+ (NSValueTransformer *)partnerJSONTransformer
{
    return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[Partner class]];
}

+ (NSValueTransformer *)fairLocationJSONTransformer
{
    return [MTLValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[PartnerShowFairLocation class]];
}

+ (NSValueTransformer *)startDateJSONTransformer
{
    return [ARStandardDateFormatter sharedFormatter].stringTransformer;
}

+ (NSValueTransformer *)endDateJSONTransformer
{
    return [ARStandardDateFormatter sharedFormatter].stringTransformer;
}

+ (NSValueTransformer *)locationJSONTransformer
{
    return [MTLValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[Location class]];
}

- (NSString *)title
{
    if (self.partner && self.partner.name) {
        return self.partner.name;

    } else if (self.name) {
        return self.name;

    } else if (self.artists.count) {
        return [self.artists[0] name];
    }

    return nil;
}

- (NSString *)subtitle
{
    if (self.fair) {
        return self.fair.name;
    }

    return self.name;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Show ( %@ at %@ ) ", self.name, self.ausstellungsdauer];
}


- (NSString *)ausstellungsdauer
{
    if (self.fair) {
        return self.fair.ausstellungsdauer;
    }
    return [self.startDate ausstellungsdauerToDate:self.endDate];
}

// Used in a maps predicate
- (BOOL)hasMapLocation
{
    return [self.fairLocation.mapPoints count] > 0;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:self.class]) {
        return [self.showID isEqualToString:[object showID]];
    }

    return [super isEqual:object];
}

- (NSUInteger)hash
{
    return self.showID.hash;
}

// TODO, this is not correct!

- (NSURL *)smallPreviewImageURL
{
    if ([self.imageVersions includes:@"square"]) {
        return [self imageURLWithFormatName:@"square"];
    }
    return [self imageURLWithFormatName:self.imageVersions.first];
}

- (NSURL *)imageURLWithFormatName:(NSString *)formatName
{
    if (self.imageAddress && self.imageVersions.count > 0 && [self.imageVersions includes:formatName]) {
        NSString *url = [self.imageAddress stringByReplacingOccurrencesOfString:@":version" withString:formatName];
        return [NSURL URLWithString:url];
    } else {
        return nil;
    }
}

- (NSString *)ausstellungsdauerAndLocation
{
    NSString *ausstellungsdauer = self.ausstellungsdauer;
    if (self.fair && self.locationInFair && ![self.locationInFair isEqualToString:@""]) {
        return [NSString stringWithFormat:@"%@, %@", ausstellungsdauer, self.locationInFair];

    } else if (self.location.city && ![self.location.city isEqualToString:@""]) {
        return [NSString stringWithFormat:@"%@, %@", ausstellungsdauer, self.location.city];

    } else {
        return self.ausstellungsdauer;
    }
}

- (AFHTTPRequestOperation *)getArtworksAtPage:(NSInteger)page success:(void (^)(NSArray *artworks))success;
{
    return [ArtsyAPI getArtworksForShow:self atPage:page success:success failure:^(NSError *_) { success(@[]);
    }];
}

#pragma mark ShareableObject

- (NSString *)publicArtsyID;
{
    return self.showID;
}

- (NSString *)publicArtsyPath
{
    return [NSString stringWithFormat:@"/show/%@", self.showID];
}

#pragma mark - ARSpotlightMetadataProvider

- (NSString *)spotlightDescription;
{
    NSString *location;
    Fair *fair = self.fair;
    if (fair && fair.location) {
        location = fair.location;
    } else {
        location = [NSString stringWithFormat:@"%@, %@ %@", self.location.city, self.location.state, self.location.country];
    }
    return [NSString stringWithFormat:@"%@\n%@\n%@", self.partner.name, location, self.ausstellungsdauer];
}

- (NSURL *)spotlightThumbnailURL;
{
    return self.smallPreviewImageURL;
}

@end
