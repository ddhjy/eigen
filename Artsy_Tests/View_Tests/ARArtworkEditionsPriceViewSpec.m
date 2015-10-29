#import "ARArtworkEditionsPriceView.h"

SpecBegin(ARArtworkEditionsPriceView);

__block ARArtworkEditionsPriceView *sut;

it(@"handles multiple editions", ^{
    Artwork *artwork = [Artwork modelWithJSON:@{
        @"edition_sets": @[
        @{
            @"id": @"asdasd",
            @"edition_size": @250,
            @"forsale": @(NO),
            @"sale_message": @"$50",
            @"dimensions": @{
                @"in": @"11' in",
                @"cm": @"27 cm"
            },
        },
        @{
            @"id": @"asdad",
            @"edition_size": @220,
            @"forsale": @(NO),
            @"sale_message": @"$30",
            @"dimensions": @{
                @"in": @"2' in",
                @"cm": @"7 cm"
            },
        }]
    }];
    sut = [[ARArtworkEditionsPriceView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    [sut updateWithArtwork:artwork];
    [sut sizeToFit];

    expect(sut).to.recordSnapshot();
});


it(@"shows a toggle when an edition and artwork are considered acquireable for sale, and edition is for sale", ^{

   });

it(@"handles not prices but for sale by saying 'available'", ^{

   });

it(@"handles a not for sale when no prices and not for sale", ^{

   });

it(@"handles a not for sale when no prices and not for sale", ^{

   });


SpecEnd
