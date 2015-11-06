#import "ARFeedViewController.h"

@class ARHeroUnitsNetworkModel;

/// The initial app view, show Hero Units and lists
/// upcoming shows.


@interface ARShowFeedViewController : ARFeedViewController

/// TODO: Cleanup this datasource business

/// Allows the state restoration to set the hero units
@property (nonatomic, strong) ARHeroUnitsNetworkModel *heroUnitDatasource;

@property (nonatomic, readonly, getter=isShowingOfflineView) BOOL showingOfflineView;

- (void)refreshFeedItems;
@end
