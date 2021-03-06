SpecBegin(SaleArtwork);

describe(@"artwork for sale", ^{
    __block SaleArtwork *_saleArtwork;

    beforeEach(^{
        _saleArtwork = [[SaleArtwork alloc] init];
    });

    it(@"has default state", ^{
        expect([_saleArtwork auctionState]).to.equal(ARAuctionStateDefault);
    });
    
    it(@"says it has no estimate when there is no min/max estimate", ^{
        _saleArtwork = [[SaleArtwork alloc] init];
        expect(_saleArtwork.hasEstimate).to.beFalsy();
    });
    
    it(@"says it has an estimate when there is no min/max estimate", ^{
        _saleArtwork = [SaleArtwork modelWithJSON:@{@"high_estimate_cents" : @20000}];
        expect(_saleArtwork.hasEstimate).to.beTruthy();

        _saleArtwork = [SaleArtwork modelWithJSON:@{@"low_estimate_cents" : @20000}];
        expect(_saleArtwork.hasEstimate).to.beTruthy();

        _saleArtwork = [SaleArtwork modelWithJSON:@{@"high_estimate_cents" : @20000, @"low_estimate_cents" : @10000}];
        expect(_saleArtwork.hasEstimate).to.beTruthy();
    });
    
    describe(@"estimate string", ^{
        
        it(@"returns a string showing both low and high ", ^{
            _saleArtwork = [SaleArtwork modelWithJSON:@{ @"high_estimate_cents" : @20000, @"low_estimate_cents" : @10000}];
            expect(_saleArtwork.estimateString).to.equal(@"Estimate: $100 – $200");
        });
        
        it(@"returns a string showing low if available ", ^{
            _saleArtwork = [SaleArtwork modelWithJSON:@{ @"low_estimate_cents" : @10000}];
            expect(_saleArtwork.estimateString).to.equal(@"Estimate: $100");
        });
        
        it(@"returns a string showing high if available", ^{
            _saleArtwork = [SaleArtwork modelWithJSON:@{ @"high_estimate_cents" : @100000}];
            expect(_saleArtwork.estimateString).to.equal(@"Estimate: $1,000");
        });
    });

    describe(@"with a bidder", ^{
        beforeEach(^{
            _saleArtwork.auction = nil;
            _saleArtwork.bidder = [[Bidder alloc] init];
        });

        it(@"sets user is registered state", ^{
            expect([_saleArtwork auctionState]).to.equal(ARAuctionStateUserIsRegistered);
        });
    });

    describe(@"with an auction that starts in the future", ^{
        beforeEach(^{
            _saleArtwork.auction = [Sale saleWithStart:[NSDate distantFuture] end:[NSDate distantFuture]];
        });

        it(@"does not change state", ^{
            expect([_saleArtwork auctionState]).to.equal(ARAuctionStateDefault);
        });
    });

    describe(@"with an auction that has started", ^{
        beforeEach(^{
            _saleArtwork.auction = [Sale saleWithStart:[NSDate distantPast] end:[NSDate distantFuture]];
        });

        it(@"sets auction started state", ^{
            expect([_saleArtwork auctionState]).to.equal(ARAuctionStateStarted);
        });
    });

    describe(@"with an auction that has ended", ^{
        beforeEach(^{
            _saleArtwork.auction = [Sale saleWithStart:[NSDate distantPast] end:[NSDate distantPast]];
        });

        it(@"sets auction ended state", ^{
            expect([_saleArtwork auctionState]).to.equal(ARAuctionStateStarted | ARAuctionStateEnded);
        });
    });

    describe(@"with a bid", ^{
        beforeEach(^{
            _saleArtwork.saleHighestBid = [Bid bidWithCents:@(99) bidID:@"lowBid"];
        });

        it(@"sets has bids state", ^{
            expect([_saleArtwork auctionState] & ARAuctionStateArtworkHasBids).to.beTruthy();
        });
    });

    describe(@"with a low bidder", ^{
        beforeEach(^{
            _saleArtwork.saleHighestBid = [Bid bidWithCents:@(99) bidID:@"lowBid"];
            _saleArtwork.positions = @[ [BidderPosition modelFromDictionary:@{ @"highestBid" : [Bid bidWithCents:@(99999) bidID:@"highBid"] }] ];
        });

        it(@"sets bidder state", ^{
            expect([_saleArtwork auctionState] & ARAuctionStateUserIsBidder).to.beTruthy();
        });
    });

    describe(@"with a highest bidder", ^{
        beforeEach(^{
            _saleArtwork.saleHighestBid = [Bid bidWithCents:@(99999) bidID:@"highBid"];
            _saleArtwork.positions = @[ [BidderPosition modelFromDictionary:@{ @"highestBid" : [Bid bidWithCents:@(99999) bidID:@"highBid"] }] ];
        });

        it(@"sets bidder state", ^{
            expect([_saleArtwork auctionState] & ARAuctionStateUserIsHighBidder).to.beTruthy();
        });
    });

    describe(@"with multiple bidder positions", ^{
        __block BidderPosition * _position;

        beforeEach(^{
            _position = [BidderPosition modelFromDictionary:@{ @"maxBidAmountCents" : @(103) }];
            _saleArtwork.positions = @[
                [BidderPosition modelFromDictionary:@{ @"maxBidAmountCents" : @(100) }],
                [BidderPosition modelFromDictionary:@{ @"maxBidAmountCents" : @(101) }],
                _position
            ];
        });

        it(@"sets max bidder position", ^{
            expect([_saleArtwork userMaxBidderPosition]).to.equal(_position);
        });
    });
});

SpecEnd;
