#import "ARShowViewController.h"
#import "ARImagePageViewController.h"
#import "ARFollowableNetworkModel.h"
#import "ARFollowableButton.h"
#import "AREmbeddedModelsViewController.h"
#import "UIViewController+FullScreenLoading.h"
#import "ARActionButtonsView.h"
#import "ARSharingController.h"
#import "ARWhitespaceGobbler.h"
#import "ARFairMapViewController.h"
#import "ARFairMapPreview.h"
#import "ARArtworkSetViewController.h"
#import "ARShowNetworkModel.h"
#import "ORStackView+ArtsyViews.h"
#import "ARFairMapPreviewButton.h"
#import "UIViewController+ARUserActivity.h"

typedef NS_ENUM(NSInteger, ARFairShowViewIndex) {
    ARFairShowViewHeader = 1,
    ARFairShowViewActionButtons,
    ARFairShowViewPartnerLabel,
    ARFairShowViewPartnerLabelFollowButton,
    ARFairShowViewShowName,
    ARFairShowViewAusstellungsdauer,
    ARFairShowViewBoothLocation,
    ARFairShowViewLocationAddress,
    ARFairShowViewDescription,
    ARFairShowViewMapPreview,
    ARFairShowViewFollowPartner,
    ARFairShowViewArtworks,
    ARFairShowViewWhitespaceGobbler,
};

static const NSInteger ARFairShowMaximumNumberOfHeadlineImages = 5;


@interface ARShowViewController () <AREmbeddedModelsDelegate, ARArtworkMasonryLayoutProvider>
@property (nonatomic, strong, readonly) ORStackScrollView *view;
@property (nonatomic, strong, readonly) ARImagePageViewController *imagePageViewController;
@property (nonatomic, strong, readonly) ARFollowableNetworkModel *followableNetwork;
@property (nonatomic, strong, readonly) AREmbeddedModelsViewController *showArtworksViewController;
@property (nonatomic, strong, readonly) ARActionButtonsView *actionButtonsView;
@property (nonatomic, strong, readwrite) Fair *fair;

@property (nonatomic, strong) NSLayoutConstraint *followButtonWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *headerImageHeightConstraint;
@property (nonatomic, strong) ARShowNetworkModel *showNetworkModel;

@end


@implementation ARShowViewController

@dynamic view;

+ (CGFloat)followButtonWidthForSize:(CGSize)size
{
    return size.width > size.height ? 281 : 315;
}

- (CGFloat)headerImageHeightForSize:(CGSize)size
{
    if (self.imagePageViewController.images.count == 0) {
        return 1;
    }

    if ([UIDevice isPhone]) {
        return 250;
    } else {
        return size.width > size.height ? 511 : 413;
    }
}

- (instancetype)initWithShowID:(NSString *)showID fair:(Fair *)fair
{
    PartnerShow *show = [[PartnerShow alloc] initWithShowID:showID];
    return [self initWithShow:show fair:fair];
}

- (instancetype)initWithShow:(PartnerShow *)show fair:(Fair *)fair
{
    self = [self init];

    _show = show;
    if (!self.fair) {
        _fair = fair ? fair : show.fair;
    }
    //_fair = fair ? fair : show.fair;

    return self;
}

- (NSString *)sideMarginPredicate
{
    return [UIDevice isPad] ? @"100" : @"40";
}

- (void)loadView
{
    self.view = [[ORStackScrollView alloc] initWithStackViewClass:[ORTagBasedAutoStackView class]];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.stackView.backgroundColor = [UIColor whiteColor];
    self.view.delegate = [ARScrollNavigationChief chief];
}

- (void)showDidLoad
{
    [self addImagePagingViewToStack];
    [self getShowHeaderImages];
    [self addActionButtonsToStack];
    [self addPartnerLabelAndFollowButtonToStack];
    [self addPartnerMetadataToStack];
    [self addMapPreview];
    [self addFairArtworksToStack];

    [self ar_removeIndeterminateLoadingIndicatorAnimated:ARPerformWorkAsynchronously];

    // Create a "be full screen with a low priority" constraint
    CGFloat height = CGRectGetHeight(self.parentViewController.parentViewController.view.bounds);
    NSString *heightConstraint = [NSString stringWithFormat:@">=%.0f@800", height - 19];
    [self.view.stackView constrainHeight:heightConstraint];

    CGFloat parentHeight = CGRectGetHeight(self.parentViewController.view.bounds) ?: CGRectGetHeight([UIScreen mainScreen].bounds);
    [self.view.stackView ensureScrollingWithHeight:parentHeight tag:ARFairShowViewWhitespaceGobbler];

    [self ar_setDataLoaded];
}

- (void)addActionButtonsToStack
{
    _actionButtonsView = [[ARActionButtonsView alloc] init];
    self.actionButtonsView.tag = ARFairShowViewActionButtons;

    // Make sure that the action view is at least 70px below the top of the stack view in case there are no install shots.
    [self.view.stackView addSubview:self.actionButtonsView withTopMargin:@"20" sideMargin:[self sideMarginPredicate]];
    [self.actionButtonsView alignTopEdgeWithView:self.view.self predicate:@">=70"];

    NSMutableArray *descriptions = [NSMutableArray array];

    [descriptions addObject: @{
        ARActionButtonImageKey: @"Artwork_Icon_Share",
        ARActionButtonHandlerKey: ^(ARCircularActionButton *sender) {
            NSURL *imageURL = nil;
            if (self.imagePageViewController.images.count) {
        imageURL = [(Image *)self.imagePageViewController.images[0] urlForThumbnailImage];
            }
            ARSharingController *sharingController = [ARSharingController sharingControllerWithObject:self.show thumbnailImageURL:imageURL];
            [sharingController presentActivityViewControllerFromView:sender];
}
}];

self.actionButtonsView.actionButtonDescriptions = descriptions;
}

- (NSDictionary *)descriptionForMapButton
{
    @weakify(self);
    return @{
        ARActionButtonImageKey : @"MapButtonAction",
        ARActionButtonHandlerKey : ^(ARCircularActionButton *sender){
            @strongify(self);
    [self handleMapButtonPress:sender];
}
}
;
}

- (void)handleMapButtonPress:(ARCircularActionButton *)sender
{
    @weakify(self);
    [self.showNetworkModel getFairMaps:^(NSArray *maps) {
        @strongify(self);
        ARFairMapViewController *viewController = [[ARSwitchBoard sharedInstance] loadMapInFair:self.fair title:self.show.title selectedPartnerShows:@[self.show]];
        [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];
    }];
}

- (void)addPartnerLabelAndFollowButtonToStack
{
    UIView *partnerLabel = [self partnerLabel];
    UIView *followButton = [self followButton];

    if ([UIDevice isPhone]) {
        [self.view.stackView addSubview:partnerLabel withTopMargin:@"0" sideMargin:[self sideMarginPredicate]];
        if (followButton) {
            [self.view.stackView addSubview:followButton withTopMargin:@"20" sideMargin:[self sideMarginPredicate]];
        }
    } else {
        UIView *containerView = [[UIView alloc] init];
        containerView.tag = ARFairShowViewPartnerLabelFollowButton;

        [containerView addSubview:partnerLabel];
        [containerView addSubview:followButton];

        [containerView constrainHeight:@"40"];
        [partnerLabel alignTop:@"0" bottom:@"0" toView:containerView];
        if (followButton) {
            [partnerLabel alignLeadingEdgeWithView:containerView predicate:@"0"];
            [followButton alignTrailingEdgeWithView:containerView predicate:@"0"];
            [followButton alignTop:@"0" bottom:@"0" toView:containerView];
            [UIView alignAttribute:NSLayoutAttributeRight ofViews:@[ partnerLabel ] toAttribute:NSLayoutAttributeLeft ofViews:@[ followButton ] predicate:@"0"];
            CGFloat followButtonWidth = [[self class] followButtonWidthForSize:self.view.frame.size];
            self.followButtonWidthConstraint = [[followButton constrainWidth:@(followButtonWidth).stringValue] firstObject];
        } else {
            [partnerLabel alignLeading:@"0" trailing:@"0" toView:containerView];
        }

        [self.view.stackView addSubview:containerView withTopMargin:@"20" sideMargin:[self sideMarginPredicate]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self ar_presentIndeterminateLoadingIndicatorAnimated:ARPerformWorkAsynchronously];

    @weakify(self);
    [self.showNetworkModel getShowInfo:^(PartnerShow *show) {
        @strongify(self);
        if (!self) { return; }

        [self.show mergeValuesForKeysFromModel:show];

        if (!self.fair) {
            self->_fair = show.fair;
        }

        [self showDidLoad];
    } failure:^(NSError *error) {
        @strongify(self);

        [self showDidLoad];
    }];
}

- (void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    self.ar_userActivityEntity = self.show;
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    [self.userActivity invalidate];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self setConstraintsForSize:size];
}

- (void)setConstraintsForSize:(CGSize)size
{
    self.followButtonWidthConstraint.constant = [self.class followButtonWidthForSize:size];
    self.headerImageHeightConstraint.constant = [self headerImageHeightForSize:size];
}

- (UILabel *)partnerLabel
{
    ARSansSerifLabelWithChevron *partnerLabel = [[ARSansSerifLabelWithChevron alloc] init];
    partnerLabel.font = [partnerLabel.font fontWithSize:16];
    partnerLabel.tag = ARFairShowViewPartnerLabel;
    BOOL showChevron = (self.show.partner.profileID && self.show.partner.defaultProfilePublic);

    partnerLabel.chevronDelta = 6;
    partnerLabel.text = self.show.partner.name.uppercaseString;
    partnerLabel.chevronHidden = !showChevron;

    if (showChevron) {
        partnerLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openArtworkPartner:)];
        [partnerLabel addGestureRecognizer:tapGesture];
    }

    [partnerLabel constrainHeight:@"40"];
    return partnerLabel;
}

- (void)addPartnerMetadataToStack
{
    ARItalicsSerifLabelWithChevron *showName = [[ARItalicsSerifLabelWithChevron alloc] init];
    showName.tag = ARFairShowViewShowName;
    showName.font = [UIFont serifFontWithSize:18];
    showName.text = self.show.fair ? self.show.fair.name : self.show.name;
    [self.view.stackView addSubview:showName withTopMargin:@"10" sideMargin:[self sideMarginPredicate]];

    ARSerifLabel *ausstellungsdauer = [self metadataLabel:self.show.ausstellungsdauer];
    ausstellungsdauer.tag = ARFairShowViewAusstellungsdauer;

    // if the show is in a fair, add booth location & possibly chevron. if it's not, add the show location (if publicly available) and description
    if (self.show.fair) {
        BOOL isNotCurrentFairContext = ![self.show.fair isEqual:self.fair];
        if (isNotCurrentFairContext) {
            // show the ausstellungsdauer and link to fair page
            [self.view.stackView addSubview:ausstellungsdauer withTopMargin:@"12" sideMargin:[self sideMarginPredicate]];

            showName.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openShowFair:)];
            [showName addGestureRecognizer:tapGesture];
            showName.chevronHidden = NO;
        } else {
            showName.chevronHidden = YES;
        }

        ARSerifLabel *boothLocation = [self metadataLabel:self.show.locationInFair];
        boothLocation.tag = ARFairShowViewBoothLocation;
        [self.view.stackView addSubview:boothLocation withTopMargin:@"8" sideMargin:[self sideMarginPredicate]];
    } else {
        // show the address of the gallery, ausstellungsdauer, and description of show
        showName.chevronHidden = YES;
        [self.view.stackView addSubview:ausstellungsdauer withTopMargin:@"12" sideMargin:[self sideMarginPredicate]];

        if (self.show.location.publiclyViewable) {
            ARSerifLabel *addressLabel = [self metadataLabel:self.show.location.addressAndCity];
            addressLabel.tag = ARFairShowViewLocationAddress;
            [self.view.stackView addSubview:addressLabel withTopMargin:@"8" sideMargin:[self sideMarginPredicate]];
        }

        if (self.show.officialDescription) {
            ARSerifLineHeightLabel *descriptionLabel = [[ARSerifLineHeightLabel alloc] initWithLineSpacing:5];
            descriptionLabel.tag = ARFairShowViewDescription;

            NSMutableDictionary *attrDictionary = [NSMutableDictionary dictionary];
            [attrDictionary setObject:[UIFont serifFontWithSize:16] forKey:NSFontAttributeName];

            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:10];

            [attrDictionary setObject:style forKey:NSParagraphStyleAttributeName];

            NSAttributedString *descriptionString = [[NSAttributedString alloc] initWithString:self.show.officialDescription attributes:attrDictionary];
            descriptionLabel.textColor = [UIColor blackColor];
            descriptionLabel.attributedText = descriptionString;

            [self.view.stackView addSubview:descriptionLabel withTopMargin:@"18" sideMargin:[self sideMarginPredicate]];
        }
    }
}

- (ARSerifLabel *)metadataLabel:(NSString *)text
{
    ARSerifLabel *label = [[ARSerifLabel alloc] init];
    label.textColor = [UIColor artsyHeavyGrey];
    label.font = [UIFont serifFontWithSize:16];
    label.text = text;
    return label;
}

- (void)openShowFair:(id)sender
{
    UIViewController *viewController = [ARSwitchBoard.sharedInstance routeProfileWithID:self.show.fair.organizer.profileID];
    [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];
}

- (void)addFairArtworksToStack
{
    // TODO: this should only load more artworks on scroll (like favorites)

    ARArtworkMasonryModule *module = [ARArtworkMasonryModule masonryModuleWithLayout:[self masonryLayoutForSize:self.view.frame.size] andStyle:AREmbeddedArtworkPresentationStyleArtworkMetadata];
    module.layoutProvider = self;
    _showArtworksViewController = [[AREmbeddedModelsViewController alloc] init];
    self.showArtworksViewController.view.tag = ARFairShowViewArtworks;
    self.showArtworksViewController.delegate = self;
    self.showArtworksViewController.activeModule = module;
    self.showArtworksViewController.constrainHeightAutomatically = YES;
    self.showArtworksViewController.showTrailingLoadingIndicator = YES;
    [self.view.stackView addViewController:self.showArtworksViewController toParent:self withTopMargin:@"0" sideMargin:nil];

    @weakify(self);
    [self getArtworksAtPage:1 onArtworks:^(NSArray *artworks) {
        @strongify(self);
        if (artworks.count > 0) {
            [self.showArtworksViewController appendItems:artworks];
        } else {
            self.showArtworksViewController.showTrailingLoadingIndicator = NO;
            [self.showArtworksViewController.view invalidateIntrinsicContentSize];
        }
    }];
}

- (void)getArtworksAtPage:(NSInteger)page onArtworks:(void (^)(NSArray *))onArtworks
{
    NSParameterAssert(onArtworks);

    @weakify(self);
    [self.showNetworkModel getArtworksAtPage:page success:^(NSArray *artworks) {
        @strongify(self);
        onArtworks(artworks);
        if (artworks.count > 0) {
            [self getArtworksAtPage:page + 1 onArtworks:onArtworks];
        }
    } failure:nil];
}

- (UIView *)followButton
{
    if (!self.show.partner.defaultProfilePublic) return nil;

    ARFollowableButton *followButton = [[ARFollowableButton alloc] init];
    followButton.tag = ARFairShowViewFollowPartner;
    if (self.show.partner.type == ARPartnerTypeGallery) {
        followButton.toFollowTitle = @"Follow Gallery";
        followButton.toUnfollowTitle = @"Following Gallery";
    }
    [followButton addTarget:self action:@selector(toggleFollowShow:) forControlEvents:UIControlEventTouchUpInside];

    Profile *profile = [[Profile alloc] initWithProfileID:self.show.partner.profileID];
    _followableNetwork = [[ARFollowableNetworkModel alloc] initWithFollowableObject:profile];
    [followButton setupKVOOnNetworkModel:self.followableNetwork];

    return followButton;
}

- (void)addMapPreview
{
    @weakify(self);
    [self.showNetworkModel getFairMaps:^(NSArray *maps) {
        @strongify(self);

        Map *map = maps.firstObject;
        if (!map) { return; }

        CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 85);
        ARFairMapPreviewButton *mapButton = [[ARFairMapPreviewButton alloc] initWithFrame:frame map:map];
        mapButton.tag = ARFairShowViewMapPreview;
        [mapButton.mapPreview addHighlightedShow:self.show animated:NO];
        [mapButton addTarget:self action:@selector(handleMapButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [self.view.stackView addSubview:mapButton withTopMargin:@"30" sideMargin:@"40"];
    }];
}

- (void)toggleFollowShow:(id)sender
{
    if ([User isTrialUser]) {
        [ARTrialController presentTrialWithContext:ARTrialContextFavoriteProfile success:^(BOOL newUser) {
            [self toggleFollowShow:sender];
        }];
        return;
    }

    self.followableNetwork.following = !self.followableNetwork.following;
}

- (void)addImagePagingViewToStack
{
    _imagePageViewController = [[ARImagePageViewController alloc] init];
    self.imagePageViewController.imageContentMode = UIViewContentModeScaleAspectFit;
    self.imagePageViewController.view.tag = ARFairShowViewHeader;
    [self.view.stackView addSubview:self.imagePageViewController.view withTopMargin:@"0" sideMargin:@"0"];

    CGFloat headerImageHeight = [self headerImageHeightForSize:self.view.frame.size];
    self.headerImageHeightConstraint = [[self.imagePageViewController.view constrainHeight:@(headerImageHeight).stringValue] firstObject];
}

- (void)getShowHeaderImages
{
    dispatch_block_t sharedResize = ^{
        self.headerImageHeightConstraint.constant = [self headerImageHeightForSize:self.view.frame.size];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    };

    [self.showNetworkModel getFairBoothArtworksAndInstallShots:self.show gotInstallImages:^(NSArray *images) {
        if (images.count == 1) {
            [self setSingleInstallShot:images.firstObject];
        } else {
            self.imagePageViewController.images = [images take:ARFairShowMaximumNumberOfHeadlineImages];
        }

        sharedResize();
    } noImages:^{
        sharedResize();
    }];
}

- (void)setSingleInstallShot:(Image *)image
{
    self.imagePageViewController.images = @[ image ];
    self.imagePageViewController.view.userInteractionEnabled = NO;
    [self.imagePageViewController setHidesPageIndicators:YES];
}

- (void)openArtworkPartner:(UITapGestureRecognizer *)gestureRecognizer
{
    Partner *partner = self.show.partner;
    UIViewController *viewController = [ARSwitchBoard.sharedInstance loadPartnerWithID:partner.profileID];
    [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];
}

- (BOOL)shouldAutorotate
{
    return [UIDevice isPad];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - DI

- (ARShowNetworkModel *)showNetworkModel
{
    if (_showNetworkModel == nil) {
        _showNetworkModel = [[ARShowNetworkModel alloc] initWithFair:self.fair show:self.show];
    }

    return _showNetworkModel;
}

#pragma mark - AREmbeddedModelsDelegate

- (void)embeddedModelsViewController:(AREmbeddedModelsViewController *)controller shouldPresentViewController:(UIViewController *)viewController
{
    [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];
}

- (void)embeddedModelsViewController:(AREmbeddedModelsViewController *)controller didTapItemAtIndex:(NSUInteger)index
{
    ARArtworkSetViewController *viewController = [ARSwitchBoard.sharedInstance loadArtworkSet:self.showArtworksViewController.items inFair:self.fair atIndex:index];
    [self.navigationController pushViewController:viewController animated:ARPerformWorkAsynchronously];
}

#pragma mark - Public Methods

- (BOOL)isFollowing
{
    return self.followableNetwork.isFollowing;
}

- (NSDictionary *)dictionaryForAnalytics
{
    return @{
        @"partner_show_id" : self.show.showID ?: @"",
        @"partner_id" : self.show.partner.partnerID ?: @"",
        @"profile_id" : self.show.partner.profileID ?: @"",
        @"fair_id" : self.fair.fairID ?: @""
    };
}

#pragma mark - ARArtworkMasonryLayoutProvider
- (ARArtworkMasonryLayout)masonryLayoutForSize:(CGSize)size
{
    return [UIDevice isPad] && (size.width > size.height) ? ARArtworkMasonryLayout3Column : ARArtworkMasonryLayout2Column;
}

@end
