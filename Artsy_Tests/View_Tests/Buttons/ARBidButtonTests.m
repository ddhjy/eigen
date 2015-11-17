#import "ARBidButton.h"

SpecBegin(ARBidButton);

__block ARBidButton *_button = nil;

beforeEach(^{
    _button = [[ARBidButton alloc] initWithFrame:CGRectMake(0, 0, 300, 46)];
});

it(@"register", ^{
    _button.auctionState = ARAuctionStateDefault;
    expect(_button).will.haveValidSnapshotNamed(@"testRegisterState");
});

it(@"registered", ^{
    _button.auctionState = ARAuctionStateUserIsRegistered;
    expect(_button).will.haveValidSnapshotNamed(@"testRegisteredState");
});

it(@"bidding open", ^{
    _button.auctionState = ARAuctionStateStarted;
    expect(_button).will.haveValidSnapshotNamed(@"testBiddingOpenState");
});

it(@"bidding closed", ^{
    _button.auctionState = ARAuctionStateEnded;
    expect(_button).will.haveValidSnapshotNamed(@"testBiddingClosedState");
});

SpecEnd;
