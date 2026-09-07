#import "AppDelegate.h"
#import "ViewController.h"
#import "Localization.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    if ([ViewController hasSavedKey]) {
        ViewController *home = [[ViewController alloc] initWithHomeMode:YES];
        UINavigationController *homeNavigationController =
            [[UINavigationController alloc] initWithRootViewController:home];
        homeNavigationController.tabBarItem = [[UITabBarItem alloc]
            initWithTitle:EXLocalizedString(@"tab.home")
                       image:[UIImage systemImageNamed:@"house.fill"]
                        tag:0];

        UITabBarController *tabs = [[UITabBarController alloc] init];
        tabs.viewControllers = @[homeNavigationController];
        tabs.selectedIndex = 0;
        tabs.tabBar.tintColor = EXThemeAccentColor();
        self.window.rootViewController = tabs;
        [self.window makeKeyAndVisible];
        [home addProtectedTabsIfNeeded];
    } else {
        self.window.rootViewController = [[ViewController alloc]
            initWithHomeMode:NO];
        [self.window makeKeyAndVisible];
    }
    return YES;
}

@end