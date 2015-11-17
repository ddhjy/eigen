#import "ARAuctionBidderStateLabel.h"
#import <Artsy+UILabels/NSNumberFormatter+ARCurrency.h>


@implementation ARAuctionBidderStateLabel

- (void)updateWithSaleArtwork:(SaleArtwork *)saleArtwork
{
    ARAuctionState state = saleArtwork.auctionState;
    if (state & ARAuctionStateUserIsHighBidder) {
        NSString *bidString = [NSNumberFormatter currencyStringForDollarCents:saleArtwork.saleHighestBid.cents];
        self.text = [NSString stringWithFormat:@"You are currently the high bidder for this lot with a bid at %@.", bidString];
        self.textColor = [UIColor artsyPurple];
    } else if (state & ARAuctionStateUserIsBidder) {
        NSString *maxBidString = [NSNumberFormatter currencyStringForDollarCents:saleArtwork.userMaxBidderPosition.maxBidAmountCents];
        self.text = [NSString stringWithFormat:@"Your max bid of %@ has been outbid.", maxBidString];
        self.textColor = [UIColor artsyRed];
    }
}

@end
