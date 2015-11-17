#import <JLRoutes/JLRoutes.h>
#import "ARExternalWebBrowserViewController.h"
#import <FLKAutoLayout/UIViewController+FLKAutoLayout.h>
#import "ARWebViewCacheHost.h"


@interface ARExternalWebBrowserViewController () <UIGestureRecognizerDelegate, UIScrollViewDelegate>
@property (nonatomic, readonly, strong) UIGestureRecognizer *gesture;
@end


@implementation ARExternalWebBrowserViewController


- (void)dealloc
{
    self.webView.navigationDelegate = nil;
    self.webView.scrollView.delegate = nil;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) {
        return nil;
    }

    // So we can separate init, from view loading
    _initialURL = url;
    self.automaticallyAdjustsScrollViewInsets = NO;

    return self;
}

- (void)loadURL:(NSURL *)URL;
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)reload;
{
    [self loadURL:self.currentURL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    ARWebViewCacheHost *webviewCache = [[ARWebViewCacheHost alloc] init];
    WKWebView *webView = [webviewCache dequeueWebView];

    webView.frame = self.view.bounds;
    webView.navigationDelegate = self;
    [self.view addSubview:webView];

    NSURLRequest *initialRequest = [NSURLRequest requestWithURL:self.initialURL];
    [webView loadRequest:initialRequest];

    UIScrollView *scrollView = webView.scrollView;
    scrollView.delegate = self;
    scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;

    // Work around bug in WKScrollView by setting private ivar directly: http://trac.webkit.org/changeset/188541
    // Once this has been fixed, we can’t completely disable this workaround, only for those OS versions with the fix.
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
#ifndef DEBUG
        @try {
#endif
            NSString *factorKey = [NSString stringWithFormat:@"%@%@ollDecelerationFactor", @"_pre", @"ferredScr"];
            NSAssert([[scrollView valueForKey:factorKey] doubleValue] < (UIScrollViewDecelerationRateNormal - 0.001),
                     @"Expected the private value to not change, maybe this bug has been fixed?");
            [scrollView setValue:@(UIScrollViewDecelerationRateNormal) forKey:factorKey];
#ifndef DEBUG
        }
        @catch (NSException *exception) {
            ARErrorLog(@"Unable to apply workaround for WebKit bug: %@", exception);
        }
#endif
    }

    _webView = webView;
}

- (void)viewWillLayoutSubviews
{
    [self.webView constrainTopSpaceToView:self.flk_topLayoutGuide predicate:@"0"];
    [self.webView alignLeading:@"0" trailing:@"0" toView:self.view];
    [self.webView alignBottomEdgeWithView:self.view predicate:@"0"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([self.navigationController isKindOfClass:ARNavigationController.class]) {
        UIGestureRecognizer *gesture = self.navigationController.interactivePopGestureRecognizer;

        [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:gesture];
        _gesture = gesture;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.gesture.delegate = nil;
    [super viewWillDisappear:animated];
}

#pragma mark - Properties

- (UIScrollView *)scrollView
{
    return self.webView.scrollView;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [[ARScrollNavigationChief chief] scrollViewDidScroll:scrollView];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark WKWebViewDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
{
    decisionHandler([self shouldLoadNavigationAction:navigationAction]);
}

- (WKNavigationActionPolicy)shouldLoadNavigationAction:(WKNavigationAction *)navigationAction;
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *URL = navigationAction.request.URL;
        if ([JLRoutes canRouteURL:URL]) {
            [JLRoutes routeURL:URL];
            return WKNavigationActionPolicyCancel;
        }
    }
    return WKNavigationActionPolicyAllow;
}

- (BOOL)shouldAutorotate
{
    return [UIDevice isPad];
}

- (NSDictionary *)dictionaryForAnalytics
{
    if (self.currentURL) {
        return @{ @"url" : self.currentURL.absoluteString,
                  @"type" : @"url" };
    }

    return nil;
}

- (NSURL *)currentURL
{
    return self.webView.URL ?: self.initialURL;
}

@end
