#import <ORStackView/ORStackView.h>
NS_ASSUME_NONNULL_BEGIN

@class EditionSet;


@interface ARArtworkEditionsPriceView : ORStackView

/// Creates the UI
- (void)updateWithArtwork:(Artwork *)artwork;

/// Runs block when a selection has changed
- (void)setSelectionUpdatedBlock:(void (^)(EditionSet *edition))updated;

/// Gets the selected edition
- (EditionSet *_Nullable)selectedEdition;

@end

NS_ASSUME_NONNULL_END
