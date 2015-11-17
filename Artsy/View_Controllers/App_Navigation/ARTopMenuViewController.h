/** Is the App's Root View Controller.

    The Top MenuVC is a member of the ARNavigationContainer protocol, this means it supports
    the standard way of pushing new view controllers into a stack using the ARSwitchBoard API.

    It currently handles the status bar API, and the Menu / Back button.
*/

#import "ARMenuAwareViewController.h"
#import "ARNavigationContainer.h"
#import "ARNavigationController.h"
#import "ARBackButtonCallbackManager.h"
#import "ARTopMenuNavigationDataSource.h"

@class ARTabContentView;


@interface ARTopMenuViewController : UIViewController <ARMenuAwareViewController, ARNavigationContainer, UIViewControllerTransitioningDelegate>

/// The main interface of the app
+ (ARTopMenuViewController *)sharedController;

/// The current navigation controller for the app from inside the tab controller
@property (readonly, nonatomic, strong) ARNavigationController *rootNavigationController;

/// The view controller associated with the currently visible view in the navigation interface, be it in a tab’s
/// navigation controller or shown modally.
@property (readonly, nonatomic, strong) UIViewController *visibleViewController;

/// The content view for the tabbed nav
@property (readonly, nonatomic, weak) ARTabContentView *tabContentView;

@property (nonatomic, strong, readwrite) ARBackButtonCallbackManager *backButtonCallbackManager;

/// Pushes the view controller into the current navigation controller or if it’s an existing view controller at the root
/// of a navigation stack of any of the tabs, it changes to that tab and pop’s to root if necessary.
///
/// Using this method makes it easier to change the navigation systems
- (void)pushViewController:(UIViewController *)viewController;

/// Same as above but with the option to animate
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/// Hides the toolbar
- (void)hideToolbar:(BOOL)hideToolbar animated:(BOOL)animated;

/// Used in search to exit out of search and back into a previous tab.
- (void)returnToPreviousTab;

/// Updates the badge counters on each tab by asking the data source for current counts.
- (void)updateBadges;

/// Present the root view controller of the navigation controller at the specified (tab) index. If a navigation stack
/// exists, it is popped to said root view controller.
- (void)presentRootViewControllerAtIndex:(NSInteger)index animated:(BOOL)animated;

/// Returns the root navigation controller for the tab at the specified index.
- (ARNavigationController *)rootNavigationControllerAtIndex:(NSInteger)index;

/// Returns the index of the tab that holds the given view controller at the root of the navigation stack or
/// `NSNotFound` in case it’s not a root view controller.
- (NSInteger)indexOfRootViewController:(UIViewController *)viewController;

/// Update the badge number on the data source for the navigation root view controller at the specified tab index.
- (void)setNotificationCount:(NSUInteger)number forControllerAtIndex:(ARTopTabControllerIndex)index;

@end
