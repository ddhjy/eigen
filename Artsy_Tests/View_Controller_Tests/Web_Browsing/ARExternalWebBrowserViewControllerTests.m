#import "ARTestHelper.h"

#import "ARExternalWebBrowserViewController.h"
#import "ARScrollNavigationChief.h"


@interface ARExternalWebBrowserViewController (Tests) <UIScrollViewDelegate>
@property (readonly, nonatomic, strong) UIWebView *webView;
@end

SpecBegin(ARExternalWebBrowserViewController);

__block ARExternalWebBrowserViewController *vc;

beforeEach(^{
    vc = [[ARExternalWebBrowserViewController alloc] initWithURL:[NSURL URLWithString:@""]];
});

afterEach(^{
    vc = nil;
});

it(@"sets the scroll view's `delegate`", ^{
    [vc ar_presentWithFrame:[UIScreen mainScreen].bounds];
    expect(vc.scrollView.delegate).to.equal(vc);
});

it(@"forwards its web view's scroll view", ^{
    [vc ar_presentWithFrame:[UIScreen mainScreen].bounds];
    expect(vc.scrollView).to.equal(vc.webView.scrollView);
});

it(@"forwards `scrollViewDidScroll` to scroll chief", ^{
    [vc ar_presentWithFrame:[UIScreen mainScreen].bounds];

    id chiefMock = [OCMockObject partialMockForObject:[ARScrollNavigationChief chief]];
    [[chiefMock expect] scrollViewDidScroll:vc.scrollView];
    [vc scrollViewDidScroll:vc.scrollView];
    [chiefMock verify];
});

SpecEnd;
