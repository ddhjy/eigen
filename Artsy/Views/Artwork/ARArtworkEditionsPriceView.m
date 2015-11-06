#import "ARArtworkEditionsPriceView.h"
#import "EditionSet.h"


@implementation ARArtworkEditionsPriceView

- (void)updateWithArtwork:(Artwork *)artwork
{
    [artwork.editionSets each:^(EditionSet *set) {
        
        UILabel *label = [[ARSerifLabel alloc] initWithFrame:CGRectZero];
        label.text = set.dimensionsInches;

        [self addSubview:label withTopMargin:@"10" sideMargin:@"20"];
    }];
}

- (void)setSelectionUpdatedBlock:(void (^)(EditionSet *edition))updated
{
}

- (EditionSet *_Nullable)selectedEdition
{
    return nil;
}

@end
