#import "ARFairFavoritesNetworkModel.h"
#import "ARNavigationButtonsViewController.h"
#import "ARArtworkSetViewController.h"
#import "ARButtonWithImage.h"
#import "ARShowViewController.h"
#import "ARFairFavoritesNetworkModel+Private.h"
#import "ARPartnerShowFeedItem.h"

const NSInteger ARFairFavoritesNetworkModelMaxRandomExhibitors = 10;


@implementation ARFairFavoritesNetworkModel

- (void)getFavoritesForNavigationsButtonsForFair:(Fair *)fair
                                        artworks:(void (^)(NSArray *artworks))artworksBlock
                               artworksByArtists:(void (^)(NSArray *artworks))appendArtistArtworksBlock
                                      exhibitors:(void (^)(NSArray *exhibitors))exhibitorsBlock
                                         artists:(void (^)(NSArray *artists))artistsBlock
                                         failure:(void (^)(NSError *error))failure
{
    if (artworksBlock) {
        // "Work" tab
        [ArtsyAPI getArtworkFavoritesForFair:fair success:^(NSArray *artworks) {
            NSArray *buttons = [artworks map:^id(Artwork *artwork) {
                return [self navigationButtonForArtwork:artwork inFair:fair];
            }];

            artworksBlock(buttons);

        } failure:failure];
    }

    // "Exhibitors" tab
    if (exhibitorsBlock) {
        [ArtsyAPI getProfileFollowsForFair:fair success:^(NSArray *follows) {
            // Create a subject that'll receive partners from either of our two code paths, below
            RACSubject *partnerSubject = [[RACSubject subject] setNameWithFormat:@"getProfileFollowsForFair:success:"];

            [[RACSignal
                combineLatest:@[[[RACObserve(fair, shows) ignore:nil] take:1], partnerSubject]
                reduce:^id(NSSet *shows, NSArray *exhibitors) {
                   return exhibitors;
                }] subscribeNext:^(NSArray *partnersArray) {
                    NSArray *buttons = [partnersArray map:^id(Partner *partner) {
                        return [self navigationButtonForPartner:partner inFair:fair];
                    }];

                    exhibitorsBlock(buttons);
                }];

            if (follows.count == 0) {
                // No content returned from API – just use random content generated once the shows property has been set
                [[[RACObserve(fair, shows) ignore:nil] take:1] subscribeNext:^(NSSet *shows) {
                    [partnerSubject sendNext:[[shows.allObjects take:ARFairFavoritesNetworkModelMaxRandomExhibitors] map:^id(PartnerShow *show) {
                        return show.partner;
                    }]];
                }];
            } else {
                // Content returned from API – filter out non-partner owners and return the owners, sending to our subject
                [partnerSubject sendNext:[[follows select:^BOOL(Follow *follow) {
                    Profile *profile = follow.profile;
                    return [profile.profileOwner isKindOfClass:[Partner class]];
                }] map:^id(Follow *follow) {
                    return follow.profile.profileOwner;
                }]];
            }

            if (!fair.shows) {
                [fair downloadShows];
            }
        } failure:failure];
    }

    if (artistsBlock || appendArtistArtworksBlock) {
        // "Artists" Tab
        [ArtsyAPI getArtistFollowsForFair:fair success:^(NSArray *follows) {
            NSArray *artists = [follows map:^id(Follow *follow) {
                return follow.artist;
            }];

            if (artists.count > 0) {
                if (artistsBlock) {
                    NSArray *buttons = [artists map:^id(Artist *artist) {
                        return [self navigationButtonForArtist:artist inFair:fair];
                    }];
                    artistsBlock(buttons);
                }

                if (appendArtistArtworksBlock) {
                    for (Artist *artist in artists) {
                        [ArtsyAPI getShowsForArtistID:artist.artistID inFairID:fair.fairID success:^(NSArray *shows) {
                            for (PartnerShow *show in shows) {
                                NSArray *buttons = [show.artworks map:^id(Artwork *artwork) {
                                    return [self navigationButtonForArtwork:artwork inFair:fair];
                                }];
                                appendArtistArtworksBlock (buttons);
                            }
                        } failure:^(NSError *error) {
                            if (failure) { failure (error); };
                        }];
                    }
                }
            }
        } failure:failure];
    }
}

// Partner = sanserif title, serif subtitle // name | location

- (NSDictionary *)navigationButtonForPartner:(Partner *)partner inFair:(Fair *)fair
{
    // avoid having to lookup a partner -> show server-side when possible
    PartnerShow *show = [fair findShowForPartner:partner];

   @weakify(self);
    return @{
        ARNavigationButtonClassKey : ARButtonWithImage.class,
        ARNavigationButtonPropertiesKey : @{
            @keypath(ARButtonWithImage.new, title) : partner.name ?: [NSNull null],
            @keypath(ARButtonWithImage.new, subtitle) : (show ? show.locationInFair : [NSNull null]) ?: [NSNull null],
            @keypath(ARButtonWithImage.new, image) : show ? [NSNull null] : [UIImage imageNamed:@"SearchThumb_LightGrey"],
            @keypath(ARButtonWithImage.new, imageURL) : (show ? [show imageURLWithFormatName:@"square"] : [NSNull null]) ?: [NSNull null]
        },
        ARNavigationButtonHandlerKey : ^(ARButtonWithImage *sender){
            @strongify(self);
    if (show) {
        [self handleShowButtonPress:show fair:fair];
    } else {
        [self handlePartnerButtonPress:partner fair:fair];
    }
}
}
;
}

// Artwork = italics serif title, sansserif subtitle // name | artist name

- (id)navigationButtonForArtwork:(Artwork *)artwork inFair:(Fair *)fair
{
   @weakify(self);
    return @{
        ARNavigationButtonClassKey : ARButtonWithImage.class,
        ARNavigationButtonPropertiesKey : @{
            @keypath(ARButtonWithImage.new, title) : artwork.title ?: [NSNull null],
            @keypath(ARButtonWithImage.new, subtitle) : [artwork.artist.name uppercaseString] ?: [NSNull null],
            @keypath(ARButtonWithImage.new, imageURL) : [artwork.defaultImage urlForSquareImage] ?: [NSNull null],
            @keypath(ARButtonWithImage.new, titleFont) : [UIFont serifItalicFontWithSize:12],
            @keypath(ARButtonWithImage.new, subtitleFont) : [UIFont sansSerifFontWithSize:12]
        },
        ARNavigationButtonHandlerKey : ^(ARButtonWithImage *sender){
            @strongify(self);
    [self handleArtworkButtonPress:artwork fair:fair];
}
}
;
}

// Artist = sanserif title, serif subtitle // name | number of works in fair

- (id)navigationButtonForArtist:(Artist *)artist inFair:(Fair *)fair
{
   @weakify(self);
    return @{
        ARNavigationButtonClassKey : ARButtonWithImage.class,
        ARNavigationButtonPropertiesKey : @{
            @keypath(ARButtonWithImage.new, title) : [artist.name uppercaseString] ?: [NSNull null],
            @keypath(ARButtonWithImage.new, subtitle) : @"", // TODO: number of works exhibited at this fair
            @keypath(ARButtonWithImage.new, imageURL) : [artist squareImageURL] ?: [NSNull null],
            @keypath(ARButtonWithImage.new, titleFont) : [UIFont sansSerifFontWithSize:12],
            @keypath(ARButtonWithImage.new, subtitleFont) : [UIFont serifFontWithSize:12]
        },
        ARNavigationButtonHandlerKey : ^(ARButtonWithImage *sender){
            @strongify(self);
    [self handleArtistButtonPress:artist fair:fair];
}
}
;
}

- (void)handlePartnerButtonPress:(Partner *)partner fair:(Fair *)fair
{
    ARFairShowFeed *feed = [[ARFairShowFeed alloc] initWithFair:fair partner:partner];
   @weakify(self);
    [feed getFeedItemsWithCursor:feed.cursor success:^(NSOrderedSet *parsed) {
        @strongify(self);
        ARPartnerShowFeedItem *showFeedItem = parsed.firstObject;
        if (feed && showFeedItem) { // check feed to retain it
            UIViewController *viewController = [[ARSwitchBoard sharedInstance] loadShow:showFeedItem.show fair:fair];
            [self.delegate fairFavoritesNetworkModel:self shouldPresentViewController:viewController];
        }
    } failure:nil];
}

- (void)handleShowButtonPress:(PartnerShow *)show fair:(Fair *)fair
{
    UIViewController *viewController = [[ARSwitchBoard sharedInstance] loadShow:show fair:fair];
    [self.delegate fairFavoritesNetworkModel:self shouldPresentViewController:viewController];
}

- (void)handleArtworkButtonPress:(Artwork *)artwork fair:(Fair *)fair
{
    ARArtworkSetViewController *viewController = [[ARSwitchBoard sharedInstance] loadArtwork:artwork inFair:fair];
    [self.delegate fairFavoritesNetworkModel:self shouldPresentViewController:viewController];
}

- (void)handleArtistButtonPress:(Artist *)artist fair:(Fair *)fair
{
    id viewController = [[ARSwitchBoard sharedInstance] loadArtistWithID:artist.artistID inFair:fair];
    [self.delegate fairFavoritesNetworkModel:viewController shouldPresentViewController:viewController];
}

@end
