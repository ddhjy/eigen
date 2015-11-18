
#import "ARAppBackgroundFetchDelegate.h"
#import "NSKeyedUnarchiver+ErrorLogging.h"


@interface ARFeed ()
- (NSOrderedSet *)parseItemsFromJSON:(NSDictionary *)result;
@end


@interface ARFileFeed ()
@end


@implementation ARFileFeed

- (instancetype)initWithFileAtPath:(NSString *)fileName
{
    self = [super init];
    if (!self) {
        return nil;
    }

    NSData *data = [NSData dataWithContentsOfFile:fileName];
    NSError *error = nil;
    if (data == nil) return self;

    id JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        return self;
    }

    [self parseItemsFromJSON:JSON];
    [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];

    return self;
}

@end


////////////////////////


@interface ARShowFeed ()
@property (nonatomic, assign) BOOL parsing;
@end


@implementation ARShowFeed

- (void)getFeedItemsWithCursor:(NSString *)cursor success:(void (^)(NSOrderedSet *))success failure:(void (^)(NSError *))failure
{
    @weakify(self);

    NSInteger pageSize = (cursor) ? 4 : 1;
    [ArtsyAPI getFeedResultsForShowsWithCursor:cursor pageSize:pageSize success:^(id JSON) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @strongify(self);
            NSOrderedSet *items = [self parseItemsFromJSON:JSON];
            dispatch_async(dispatch_get_main_queue(), ^{
                success(items);
            });
        });

    } failure:failure];
}

@end


////////////////////////


@interface ARProfileFeed ()
@property (nonatomic, strong) Profile *profile;
@end


@implementation ARProfileFeed

- (instancetype)initWithProfile:(Profile *)profile
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _profile = profile;
    return self;
}

- (void)getFeedItemsWithCursor:(NSString *)cursor success:(void (^)(NSOrderedSet *))success failure:(void (^)(NSError *))failure
{
    @weakify(self);
    [ArtsyAPI getFeedResultsForProfile:self.profile withCursor:cursor success:^(id JSON) {
        @strongify(self);
        success([self parseItemsFromJSON:JSON]);
    } failure:failure];
}

@end


////////////////////////


@interface ARFairOrganizerFeed ()
@property (nonatomic, strong) FairOrganizer *fairOrganizer;
@end


@implementation ARFairOrganizerFeed

- (instancetype)initWithFairOrganizer:(FairOrganizer *)fairOrganizer
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _fairOrganizer = fairOrganizer;
    return self;
}

- (void)getFeedItemsWithCursor:(NSString *)cursor success:(void (^)(NSOrderedSet *))success failure:(void (^)(NSError *))failure
{
    @weakify(self);
    [ArtsyAPI getFeedResultsForFairOrganizer:self.fairOrganizer withCursor:cursor success:^(id JSON) {
        ar_dispatch_async(^{
            @strongify(self);
            NSOrderedSet *items = [self parseItemsFromJSON:JSON];

            ar_dispatch_main_queue(^{
                success(items);
            });
        });
    } failure:failure];
}

@end


////////////////////////


@interface ARFairShowFeed ()
@property (nonatomic, strong) Fair *fair;
@property (nonatomic, strong) Partner *partner;
@end


@implementation ARFairShowFeed

- (instancetype)initWithFair:(Fair *)fair
{
    return [self initWithFair:fair partner:nil];
}

- (instancetype)initWithFair:(Fair *)fair partner:(Partner *)partner
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _fair = fair;
    _partner = partner;
    return self;
}

- (void)getFeedItemsWithCursor:(NSString *)cursor success:(void (^)(NSOrderedSet *))success failure:(void (^)(NSError *))failure
{
    @weakify(self);

    [ArtsyAPI getFeedResultsForFairShows:self.fair partnerID:self.partner.partnerID withCursor:cursor success:^(id JSON) {
        ar_dispatch_async(^{
            @strongify(self);

            NSOrderedSet *items = [self parseItemsFromJSON:JSON];

            ar_dispatch_main_queue(^{
                success(items);
            });
        });
    } failure:failure];
}

@end
