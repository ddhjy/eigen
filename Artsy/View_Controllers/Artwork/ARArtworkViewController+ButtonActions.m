#import <ARAnalytics/ARAnalytics.h>
#import <Adjust/Adjust.h>
#import <UIAlertView+Blocks/UIAlertView+Blocks.h>

#import "ARArtworkViewController+ButtonActions.h"
#import "ARZoomArtworkImageViewController.h"
#import "ARArtworkInfoViewController.h"
#import "ARAuctionArtworkResultsViewController.h"
#import "ARViewInRoomViewController.h"
#import "ARSharingController.h"
#import "ARArtworkPreviewImageView.h"
#import "ARShowViewController.h"
#import "ARHeartButton.h"
#import "ARFairViewController.h"
#import "ARRouter.h"
#import "ARInternalMobileWebViewController.h"
#import "ARFairMapViewController.h"
#import "ARBidButton.h"
#import "ARAnalyticsConstants.h"


@implementation ARArtworkViewController (ButtonActions)

#pragma mark - ARArtworkPreviewImageViewDelegate

- (void)tappedTileableImagePreview
{
    ARZoomArtworkImageViewController *zoomImageVC = [[ARZoomArtworkImageViewController alloc] initWithImage:self.artwork.defaultImage];
    zoomImageVC.suppressZoomViewCreation = (self.fair == nil);
    [self.navigationController pushViewController:zoomImageVC animated:ARPerformWorkAsynchronously];
}

#pragma mark - ARArtworkPreviewActionsViewDelegate

- (void)tappedArtworkFavorite:(ARHeartButton *)sender
{
    if ([User isTrialUser]) {
        [ARTrialController presentTrialWithContext:ARTrialContextFavoriteArtwork success:^(BOOL newUser) {
            [self tappedArtworkFavorite:sender];
        }];
        return;
    }

    BOOL hearted = !sender.hearted;
    [sender setHearted:hearted animated:YES];

    [self.artwork setFollowState:sender.isHearted success:^(id json) {
        [NSNotificationCenter.defaultCenter postNotificationName:ARFairRefreshFavoritesNotification object:nil];
    } failure:^(NSError *error) {
        [ARNetworkErrorManager presentActiveError:error withMessage:@"Failed to save artwork."];
        [sender setHearted:!hearted animated:YES];
    }];
}

- (void)tappedArtworkShare:(UIButton *)sender
{
    NSURL *thumbnailImageURL = nil;
    UIImage *image = nil;
    if (self.artwork.defaultImage.downloadable) {
        thumbnailImageURL = self.artwork.defaultImage.urlForThumbnailImage;
        image = self.imageView.image;
    } else if (self.artwork.canShareImage) {
        thumbnailImageURL = self.artwork.defaultImage.urlForThumbnailImage;
    }
    ARSharingController *sharingController = [ARSharingController sharingControllerWithObject:self.artwork
                                                                            thumbnailImageURL:thumbnailImageURL
                                                                                        image:image];
    [sharingController presentActivityViewControllerFromView:sender];
}


- (void)tappedArtworkViewInRoom
{
    ARViewInRoomViewController *viewInRoomVC = [[ARViewInRoomViewController alloc] initWithArtwork:self.artwork];
    [self.navigationController pushViewController:viewInRoomVC animated:ARPerformWorkAsynchronously];
}

- (void)tappedArtworkViewInMap
{
    [ArtsyAPI getShowsForArtworkID:self.artwork.artworkID inFairID:self.fair.fairID success:^(NSArray *shows) {
        if (shows.count > 0) {
            ARFairMapViewController *viewController = [[ARSwitchBoard sharedInstance] loadMapInFair:self.fair title:self.artwork.partner.name selectedPartnerShows:shows];
            [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];
        }
    } failure:^(NSError *error){
        // ignore
    }];
}

#pragma mark - ARArtworkActionsViewButtonDelegate

- (void)tappedContactGallery
{
    if (ARIsRunningInDemoMode) {
        [UIAlertView showWithTitle:nil message:@"Feature not enabled for this demo" cancelButtonTitle:@"OK" otherButtonTitles:nil tapBlock:nil];
        return;
    }

    ARInquireForArtworkViewController *inquireVC = [[ARInquireForArtworkViewController alloc] initWithPartnerInquiryForArtwork:self.artwork fair:self.fair];
    [inquireVC presentFormWithInquiryURLRepresentation:[self inquiryURLRepresentation]];
}

- (void)tappedContactRepresentative
{
    if (ARIsRunningInDemoMode) {
        [UIAlertView showWithTitle:nil message:@"Feature not enabled for this demo" cancelButtonTitle:@"OK" otherButtonTitles:nil tapBlock:nil];
        return;
    }

    ARInquireForArtworkViewController *inquireVC = [[ARInquireForArtworkViewController alloc] initWithAdminInquiryForArtwork:self.artwork fair:self.fair];
    [inquireVC presentFormWithInquiryURLRepresentation:[self inquiryURLRepresentation]];
}

- (void)tappedAuctionInfo
{
    ARInternalMobileWebViewController *viewController = [[ARInternalMobileWebViewController alloc] initWithURL:[NSURL URLWithString:@"/how-auctions-work"]];
    [[ARTopMenuViewController sharedController] pushViewController:viewController];
}

- (void)tappedConditionsOfSale
{
    ARInternalMobileWebViewController *viewController = [[ARInternalMobileWebViewController alloc] initWithURL:[NSURL URLWithString:@"/conditions-of-sale"]];
    [[ARTopMenuViewController sharedController] pushViewController:viewController];
}

- (void)tappedBidButton
{
    if ([User isTrialUser]) {
        [ARTrialController presentTrialWithContext:ARTrialContextAuctionBid success:^(BOOL newUser) {
            [self tappedBidButton];
        }];
        return;
    }
    [self.artwork onSaleArtworkUpdate:^(SaleArtwork *saleArtwork) {
        [self bidCompleted:saleArtwork];
    } failure:^(NSError *error) {
        ARErrorLog(@"Can't get sale to bid for artwork %@. Error: %@", self.artwork.artworkID, error.localizedDescription);
    }];
}

- (void)bidCompleted:(SaleArtwork *)saleArtwork
{
    [ARAnalytics setUserProperty:@"has_started_bid" toValue:@"true"];

    ADJEvent *event = [ADJEvent eventWithEventToken:ARAdjustSentArtworkInquiry];
    [Adjust trackEvent:event];

    UIViewController *viewController = [ARSwitchBoard.sharedInstance loadBidUIForArtwork:self.artwork.artworkID
                                                                                  inSale:saleArtwork.auction.saleID];
    [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];
}

- (void)tappedBuyersPremium
{
    [self.artwork onSaleArtworkUpdate:^(SaleArtwork *saleArtwork) {
        NSString *path = [NSString stringWithFormat:@"/auction/%@/buyers-premium", saleArtwork.auction.saleID];
        UIViewController *viewController = [ARSwitchBoard.sharedInstance loadPath:path fair:self.fair];
        [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];

    } failure:^(NSError *error) {
        ARErrorLog(@"Can't get sale to bid for artwork %@. Error: %@", self.artwork.artworkID, error.localizedDescription);
    }];
}

- (void)tappedBuyButton
{
    if ([User isTrialUser]) {
        [ARTrialController presentTrialWithContext:ARTrialContextArtworkOrder success:^(BOOL newUser) {
            [self tappedBuyButton];
        }];
        return;
    }

    // We currently don't have a UI for a user to select from multiple editions. Instead, send the user
    // to the inquiry form.
    if (self.artwork.hasMultipleEditions) {
        [self tappedContactGallery];
        return;
    }

    // If the artwork has only 1 edition, use that edition id. Otherwise our POST request will fail.
    NSString *editionSetID = nil;
    if (self.artwork.editionSets.count > 0) {
        editionSetID = [[self.artwork.editionSets objectAtIndex:0] valueForKey:@"id"];
    }

    @weakify(self);
    [ArtsyAPI createPendingOrderWithArtworkID:self.artwork.artworkID editionSetID:editionSetID success:^(id JSON) {

        NSString *orderID = [JSON valueForKey:@"id"];
        NSString *resumeToken = [JSON valueForKey:@"token"];
        ARErrorLog(@"Created order %@", orderID);
        UIViewController *controller = [[ARSwitchBoard sharedInstance] loadOrderUIForID:orderID resumeToken:resumeToken];
        [self.navigationController pushViewController:controller animated:YES];

    }
        failure:^(NSError *error) {
        @strongify(self);
        ARErrorLog(@"Creating a new order failed. Error: %@,\n", error.localizedDescription);
        [self tappedContactGallery];
        }];
}

- (void)tappedAuctionResults
{
    UIViewController *viewController = [ARSwitchBoard.sharedInstance loadAuctionResultsForArtwork:self.artwork];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)tappedMoreInfo
{
    UIViewController *viewController = [ARSwitchBoard.sharedInstance loadMoreInfoForArtwork:self.artwork];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - ARArtworkDetailViewDelegate

- (void)tappedOpenArtworkPartner
{
    Partner *partner = self.artwork.partner;
    if (self.fair) {
        [ArtsyAPI getShowsForArtworkID:self.artwork.artworkID inFairID:self.fair.fairID success:^(NSArray *shows) {
            if (shows.count > 0) {
                UIViewController *viewController = [[ARSwitchBoard sharedInstance] loadShow:shows.firstObject fair:self.fair];
                [self.navigationController pushViewController:viewController animated:YES];
            }
        } failure:^(NSError *error){
            // ignore
        }];
    } else if (partner.defaultProfilePublic) {
        UIViewController *viewController = [ARSwitchBoard.sharedInstance loadPartnerWithID:partner.profileID];
        if (viewController) {
            [self.navigationController pushViewController:viewController animated:YES];
        }
    } else if (partner.website.length) {
        UIViewController *viewController = [ARSwitchBoard.sharedInstance loadURL:[NSURL URLWithString:partner.website]];
        if (viewController) {
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

- (void)tappedOpenFair
{
    Fair *fair = self.fair ?: self.artwork.fair;
    NSString *fairID = fair.defaultProfileID ?: fair.organizer.profileID;
    UIViewController *viewController = [ARSwitchBoard.sharedInstance routeProfileWithID:fairID];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)tappedOpenArtworkArtist
{
    UIViewController *viewController = [ARSwitchBoard.sharedInstance loadArtistWithID:self.artwork.artist.artistID inFair:self.fair];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
