#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (instancetype)initWithHomeMode:(BOOL)homeMode;
+ (BOOL)hasSavedKey;
- (void)addProtectedTabsIfNeeded;

@end