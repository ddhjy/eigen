#import "ARSimpleShowFeedViewController.h"
#import "ARModernPartnerShowTableViewCell.h"
#import "ARFeedLinkUnitViewController.h"
#import "ARHeroUnitViewController.h"
#import "ARHeroUnitsNetworkModel.h"
#import "ARFeedTimeline.h"
#import "ARSimpleShowFeedViewController+Konami.h"
#import "UIViewController+SimpleChildren.h"
#import "ARReusableLoadingView.h"
#import "ARPartnerShowFeedItem.h"
#import "AROfflineView.h"

#import <ObjectiveSugar/ObjectiveSugar.h>
#import <ARAnalytics/ARAnalytics.h>
#import "ARAnalyticsConstants.h"

#import "ArtsyAPI+Private.h"
#import "ARPageSubtitleView.h"
#import "ARShowFeedNetworkStatusModel.h"

static NSString *ARShowCellIdentifier = @"ARShowCellIdentifier";


@interface ARSimpleShowFeedViewController () <ARModernPartnerShowTableViewCellDelegate, ARNetworkErrorAwareViewController>

@end


@interface ARSimpleShowFeedViewController ()
@property (nonatomic, readonly, strong) ARSectionData *section;
@property (nonatomic, readonly, strong) ORStackView *headerStackView;

@property (nonatomic, strong) ARFeedTimeline *feedTimeline;
@property (nonatomic, strong) ARShowFeedNetworkStatusModel *networkStatus;

@end


@implementation ARSimpleShowFeedViewController

- (instancetype)initWithFeedTimeline:(ARFeedTimeline *)timeline
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (!self) {
        return nil;
    }

    _feedTimeline = timeline;
    _feedLinkVC = [[ARFeedLinkUnitViewController alloc] init];
    _heroUnitVC = [[ARHeroUnitViewController alloc] init];
    _networkStatus = [[ARShowFeedNetworkStatusModel alloc] initWithShowFeedVC:self];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundColor = [UIColor blackColor];
    [self registerClass:ARModernPartnerShowTableViewCell.class forCellReuseIdentifier:ARShowCellIdentifier];

    ORStackView *stack = [[ORStackView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    [stack addViewController:self.heroUnitVC toParent:self withTopMargin:@"0" sideMargin:@"0"];
    [stack addViewController:self.feedLinkVC toParent:self withTopMargin:@"20" sideMargin:@"40"];

    ARPageSubTitleView *featuredShowsLabel = [[ARPageSubTitleView alloc] initWithTitle:@"Current Shows"];
    [featuredShowsLabel constrainHeight:@"40"];
    [stack addSubview:featuredShowsLabel withTopMargin:@"20" sideMargin:@"40"];

    _headerStackView = stack;

    self.tableView.tableHeaderView = [self wrapperForHeaderStack];

    // This is done in its own category now
    [self registerKonamiCode];

    // Older builds used to assume that one day you might hit the end of the feed. ( 'Cause you could in 1.0. )
    // I think it's now a safe assumption that you can never hit the end of the shows feed. :tada:

    ARReusableLoadingView *footerView = [[ARReusableLoadingView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    [footerView startIndeterminateAnimated:NO];
    self.tableView.tableFooterView = footerView;


    [ArtsyAPI getXappTokenWithCompletion:^(NSString *xappToken, NSDate *expirationDate) {
        [self.feedLinkVC fetchLinks:^{

            UIView *newWrapper = [self wrapperForHeaderStack];
            self.tableView.tableHeaderView = newWrapper;
        }];
    }];

    _section = [[ARSectionData alloc] init];

    /// Deal with background cached'd data
    for (ARPartnerShowFeedItem *show in self.feedTimeline.items) {
        [self addShowToTable:show];
    }
    self.tableViewData = [[ARTableViewData alloc] initWithSectionDataArray:@[ self.section ]];
}

- (UIView *)wrapperForHeaderStack
{
    // A tableview header cannot be resized dynamically. This gets tricksy when
    // we want to add things like the feed links below the hero units.

    // So we generate a new wrapper view, ensure all AL has been ran in the
    // stack and create a new wrapper to put our stack in and the tableview
    // uses that.

    UIView *wrapper = [[UIView alloc] init];
    UIView *stack = self.headerStackView;

    [stack updateConstraints];
    wrapper.frame = (CGRect){
        .size = [stack systemLayoutSizeFittingSize:self.view.bounds.size],
        .origin = CGPointZero};

    stack.frame = wrapper.bounds;
    [stack removeFromSuperview];

    [wrapper addSubview:stack];
    [stack alignToView:wrapper];
    return wrapper;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)refreshFeedItems
{
    [ARAnalytics startTimingEvent:ARAnalyticsInitialFeedLoadTime];
    @weakify(self);

    [ArtsyAPI getXappTokenWithCompletion:^(NSString *xappToken, NSDate *expirationDate) {
        [self.feedTimeline getNewItems:^(NSArray *items) {
            @strongify(self);

            for (ARPartnerShowFeedItem *show in items) {
                [self addShowToTable:show];
            }
            [self.tableView reloadData];

            [self loadNextFeedPage];
            [self.heroUnitVC.heroUnitNetworkModel downloadHeroUnits];
            [self.networkStatus hideOfflineView];

            [ARAnalytics finishTimingEvent:ARAnalyticsInitialFeedLoadTime];

        } failure:^(NSError *error) {
            ARErrorLog(@"There was an error getting newest items for the feed: %@", error.localizedDescription);

            // So that it won't stop the first one
            [self.networkStatus.offlineView refreshFailed];
            [self.networkStatus showOfflineViewIfNeeded];
            
            [self performSelector:@selector(refreshFeedItems) withObject:nil afterDelay:3];
            [ARAnalytics finishTimingEvent:ARAnalyticsInitialFeedLoadTime];
        }];
    } failure:^(NSError *error) {
        [self.networkStatus.offlineView refreshFailed];
    }];
}

- (void)loadNextFeedPage
{
    [self.feedTimeline getNextPage:^(NSArray *items) {
        for (ARPartnerShowFeedItem *show in items) {
            [self addShowToTable:show];
        }
        [self.tableView reloadData];

    } failure:^(NSError *error) {
        ARErrorLog(@"There was an error getting next feed page: %@", error.localizedDescription);
        [ARNetworkErrorManager presentActiveError:error withMessage:@"We're having trouble accessing the show feed."];

    } completion:^{

    }];
}

- (void)addShowToTable:(ARPartnerShowFeedItem *)show
{
    ARCellData *data = [[ARCellData alloc] initWithIdentifier:ARShowCellIdentifier];
    [data setCellConfigurationBlock:^(ARModernPartnerShowTableViewCell *cell) {
        [cell configureWithFeedItem:show];
        cell.delegate = self;
    }];

    BOOL useLandscape = self.view.bounds.size.width > self.view.bounds.size.height;
    data.height = [ARModernPartnerShowTableViewCell heightForItem:show useLandscapeValues:useLandscape];
    [self.section addCellData:data];
}

#pragma mark - ARMenuAwareViewController

- (BOOL)hidesBackButton
{
    return self.navigationController.viewControllers.count <= 1;
}

- (BOOL)hidesToolbarMenu
{
    return self.networkStatus.showingOfflineView;
}

- (BOOL)hidesSearchButton;
{
    return self.networkStatus.showingOfflineView;
}

#pragma mark - ARNetworkErrorAwareViewController

- (BOOL)shouldShowActiveNetworkError
{
    return !self.networkStatus.isShowingOfflineView;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // nav transitions wanna send us scroll events after the transition and we are all like
    // nuh-uh

    if (self.navigationController.topViewController == self && scrollView == self.tableView) {
        [[ARScrollNavigationChief chief] scrollViewDidScroll:scrollView];
    }

    if ((scrollView.contentSize.height - scrollView.contentOffset.y) < scrollView.bounds.size.height) {
        [self loadNextFeedPage];
    }
}

#pragma mark - Orientation

- (BOOL)shouldAutorotate
{
    return [UIDevice isPad];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - ARModernPartnerShowTableViewCellDelegate

- (void)modernPartnerShowTableViewCell:(ARModernPartnerShowTableViewCell *)cell shouldShowViewController:(UIViewController *)viewController
{
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
