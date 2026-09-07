#import "ViewController.h"
#import "PatchProjectsViewController.h"
#import "CleanerViewController.h"
#import "SettingsViewController.h"
#import "Localization.h"
#import "ExploitCompatibility.h"
#import "SandboxAccessBridge.h"
#import <Foundation/Foundation.h>
#import <stdlib.h>

static NSString * const kExternalKey = @"BORED";
static NSString * const kExternalLicenseCreatedAt = @"ExternalLicenseCreatedAt";
static NSString * const kExternalKeyValidated = @"ExternalKeyValidated";
static NSString * const kExternalKeyFailedAttempts = @"ExternalKeyFailedAttempts";
static NSString * const kExternalKeyLockoutUntil = @"ExternalKeyLockoutUntil";
static NSTimeInterval const kExternalLicenseDuration = 24.0 * 60.0 * 60.0;

static UIColor *ExternalAccentColor(void) {
    return EXThemeAccentColor();
}

static UIColor *ExternalFixedStatusGreen(void) {
    return [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
}

static UIColor *ExternalOrangeStatusColor(void) {
    return [UIColor colorWithRed:1.0 green:0.65 blue:0.20 alpha:1.0];
}

static UIColor *ExternalDimmedAccentColor(void) {
    UIColor *accent = ExternalAccentColor();
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 1.0;
    if ([accent getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return [UIColor colorWithRed:red * 0.45
                               green:green * 0.45
                                blue:blue * 0.45
                               alpha:alpha];
    }
    return [accent colorWithAlphaComponent:0.45];
}

@interface ViewController ()
@property (nonatomic, strong) UIButton *pasteKeyButton;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) UIView *homeView;
@property (nonatomic, strong) UIButton *patchesButton;
@property (nonatomic) BOOL homeMode;
@property (nonatomic, strong) UILabel *modelValue;
@property (nonatomic, strong) UILabel *iosValue;
@property (nonatomic, strong) UILabel *compatibilityValue;
@property (nonatomic, strong) UILabel *deviceValue;
@property (nonatomic, strong) UILabel *runtimeValue;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *deviceTitleLabel;
@property (nonatomic, strong) UILabel *modelKeyLabel;
@property (nonatomic, strong) UILabel *iosKeyLabel;
@property (nonatomic, strong) UILabel *compatibilityKeyLabel;
@property (nonatomic, strong) UILabel *deviceKeyLabel;
@property (nonatomic, strong) UILabel *runtimeKeyLabel;
@property (nonatomic, strong) UILabel *versionKeyLabel;
@property (nonatomic, strong) UILabel *versionValueLabel;
@property (nonatomic, strong) UIButton *sandboxButton;
@property (nonatomic) BOOL validationInProgress;
@property (nonatomic) BOOL isExitingForLockout;
- (BOOL)hasFileAccess;
- (void)validateEnteredKey:(NSString *)enteredKey;
- (void)addProtectedTabsIfNeeded;
@end

@implementation ViewController

- (instancetype)initWithHomeMode:(BOOL)homeMode {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _homeMode = homeMode;
    }
    return self;
}

+ (BOOL)hasSavedKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:kExternalKeyValidated]) return NO;

    NSNumber *createdAt = [defaults objectForKey:kExternalLicenseCreatedAt];
    if (![createdAt isKindOfClass:NSNumber.class]) return NO;
    return [[NSDate date] timeIntervalSince1970] - createdAt.doubleValue
        < kExternalLicenseDuration;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshAppearance)
                                                 name:EXThemeDidChangeNotification
                                               object:nil];
    self.view.backgroundColor = UIColor.blackColor;
    if (self.homeMode) {
        [self buildHomeView];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithImage:[UIImage systemImageNamed:@"gearshape"]
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(openSettings)];
        self.navigationItem.rightBarButtonItem.accessibilityLabel =
            EXLocalizedString(@"accessibility.open_settings");
        self.navigationController.navigationBar.tintColor = ExternalAccentColor();
    } else {
        [self buildLoginView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.homeMode && [self lockoutRemaining] > 0.0) {
        [self showLockoutAndExit];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildLoginView {
    self.loginView = [[UIView alloc] initWithFrame:CGRectZero];
    self.loginView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loginView];

    [NSLayoutConstraint activateConstraints:@[
        [self.loginView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.loginView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.loginView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.loginView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    // The login intentionally exposes one control only.  The key is read
    // directly from the clipboard when this button is pressed.
    self.pasteKeyButton = [self filledButtonWithTitle:EXLocalizedString(@"login.paste_key")];
    [self.pasteKeyButton addTarget:self action:@selector(pasteKey)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.loginView addSubview:self.pasteKeyButton];

    self.errorLabel = [self labelWithText:@"" size:13 weight:UIFontWeightMedium
                                     color:[UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0]];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loginView addSubview:self.errorLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.pasteKeyButton.centerXAnchor constraintEqualToAnchor:self.loginView.centerXAnchor],
        [self.pasteKeyButton.centerYAnchor constraintEqualToAnchor:self.loginView.centerYAnchor],
        [self.pasteKeyButton.leadingAnchor constraintEqualToAnchor:self.loginView.leadingAnchor constant:32],
        [self.pasteKeyButton.trailingAnchor constraintEqualToAnchor:self.loginView.trailingAnchor constant:-32],
        [self.pasteKeyButton.heightAnchor constraintEqualToConstant:54],
        [self.errorLabel.topAnchor constraintEqualToAnchor:self.pasteKeyButton.bottomAnchor constant:10],
        [self.errorLabel.leadingAnchor constraintEqualToAnchor:self.pasteKeyButton.leadingAnchor],
        [self.errorLabel.trailingAnchor constraintEqualToAnchor:self.pasteKeyButton.trailingAnchor]
    ]];
}

- (NSTimeInterval)lockoutRemaining {
    NSNumber *until = [[NSUserDefaults standardUserDefaults]
        objectForKey:kExternalKeyLockoutUntil];
    if (![until isKindOfClass:NSNumber.class]) return 0.0;
    NSTimeInterval remaining = until.doubleValue - [NSDate date].timeIntervalSince1970;
    if (remaining <= 0.0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:kExternalKeyLockoutUntil];
        [defaults removeObjectForKey:kExternalKeyFailedAttempts];
        return 0.0;
    }
    return remaining;
}

- (void)showLockoutAndExit {
    if (self.isExitingForLockout) return;
    self.isExitingForLockout = YES;
    self.pasteKeyButton.enabled = NO;
    self.errorLabel.textColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
    self.errorLabel.text = EXLocalizedString(@"login.locked_out");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        exit(EXIT_SUCCESS);
    });
}

- (void)pasteKey {
    if (self.validationInProgress) return;
    if ([self lockoutRemaining] > 0.0) {
        [self showLockoutAndExit];
        return;
    }

    NSString *enteredKey = [UIPasteboard generalPasteboard].string;
    enteredKey = [enteredKey stringByTrimmingCharactersInSet:
                  NSCharacterSet.whitespaceAndNewlineCharacterSet].uppercaseString;
    if (!enteredKey.length) {
        self.errorLabel.textColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
        self.errorLabel.text = EXLocalizedString(@"login.no_key_in_clipboard");
        return;
    }

    self.validationInProgress = YES;
    self.pasteKeyButton.enabled = NO;
    self.errorLabel.textColor = ExternalOrangeStatusColor();
    self.errorLabel.text = EXLocalizedString(@"login.validating_access");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        self.validationInProgress = NO;
        [self validateEnteredKey:enteredKey];
    });
}

- (void)validateEnteredKey:(NSString *)enteredKey {
    if ([enteredKey isEqualToString:kExternalKey]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *createdAt = [defaults objectForKey:kExternalLicenseCreatedAt];
        if (createdAt != nil &&
            [[NSDate date] timeIntervalSince1970] - createdAt.doubleValue >= kExternalLicenseDuration) {
            self.pasteKeyButton.enabled = YES;
            self.errorLabel.textColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
            self.errorLabel.text = EXLocalizedString(@"login.license_expired");
            return;
        }
        if (createdAt == nil) {
            [defaults setDouble:[NSDate date].timeIntervalSince1970
                         forKey:kExternalLicenseCreatedAt];
        }
        [defaults setBool:YES forKey:kExternalKeyValidated];
        [defaults removeObjectForKey:kExternalKeyFailedAttempts];
        [defaults removeObjectForKey:kExternalKeyLockoutUntil];
        [defaults synchronize];
        self.pasteKeyButton.enabled = NO;
        // Do not replace the window root from inside an animation block that
        // is currently mutating this view hierarchy. On some iOS versions
        // that can detach the view while UIKit is laying out the transition
        // and terminate the process.
        [self presentMainTabs];
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger attempts = [defaults integerForKey:kExternalKeyFailedAttempts] + 1;
        [defaults setInteger:attempts forKey:kExternalKeyFailedAttempts];
        if (attempts >= 3) {
            [defaults setDouble:[NSDate date].timeIntervalSince1970 + 60.0 * 60.0
                         forKey:kExternalKeyLockoutUntil];
            [defaults synchronize];
            [self showLockoutAndExit];
        } else {
            self.pasteKeyButton.enabled = YES;
            self.errorLabel.textColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
            self.errorLabel.text = EXLocalizedString(@"login.invalid_key");
        }
    }
}

- (void)buildHomeView {
    self.navigationItem.title = @"";
    self.homeView = [[UIView alloc] initWithFrame:CGRectZero];
    self.homeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.homeView];
    [NSLayoutConstraint activateConstraints:@[
        [self.homeView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.homeView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.homeView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.homeView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    // Home is a fixed dashboard; Files is the only scrolling area.
    scrollView.alwaysBounceVertical = NO;
    scrollView.scrollEnabled = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [self.homeView addSubview:scrollView];

    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:contentView];
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:self.homeView.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.homeView.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:self.homeView.safeAreaLayoutGuide.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.homeView.safeAreaLayoutGuide.bottomAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor]
    ]];

    UIImageView *smallLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ExternalIcon"]];
    smallLogo.translatesAutoresizingMaskIntoConstraints = NO;
    smallLogo.contentMode = UIViewContentModeScaleAspectFit;
    smallLogo.layer.cornerRadius = 16;
    smallLogo.clipsToBounds = YES;
    [contentView addSubview:smallLogo];

    UILabel *heading = [self labelWithText:@"EXTERNAL iOS" size:28 weight:UIFontWeightBold color:UIColor.whiteColor];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:heading];

    UILabel *hint = [self labelWithText:EXLocalizedString(@"dashboard.home_hint")
                                   size:15 weight:UIFontWeightRegular
                                   color:[UIColor colorWithWhite:0.58 alpha:1.0]];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:hint];
    self.hintLabel = hint;

    UIView *deviceCard = [[UIView alloc] initWithFrame:CGRectZero];
    deviceCard.translatesAutoresizingMaskIntoConstraints = NO;
    deviceCard.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    deviceCard.layer.cornerRadius = 16.0;
    deviceCard.layer.borderColor = [UIColor colorWithWhite:0.24 alpha:1.0].CGColor;
    deviceCard.layer.borderWidth = 1.0;
    [contentView addSubview:deviceCard];

    UIButton *sandboxButton = [UIButton buttonWithType:UIButtonTypeSystem];
    sandboxButton.translatesAutoresizingMaskIntoConstraints = NO;
    [sandboxButton setTitle:EXLocalizedString(@"dashboard.access_button")
                   forState:UIControlStateNormal];
    [sandboxButton setTitleColor:UIColor.blackColor
                         forState:UIControlStateNormal];
    [sandboxButton setTitleColor:UIColor.blackColor
                         forState:UIControlStateDisabled];
    sandboxButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    sandboxButton.backgroundColor = ExternalAccentColor();
    sandboxButton.layer.cornerRadius = 10.0;
    sandboxButton.layer.masksToBounds = YES;
    [sandboxButton addTarget:self
                      action:@selector(enableFileAccess)
            forControlEvents:UIControlEventTouchUpInside];
    [deviceCard addSubview:sandboxButton];
    self.sandboxButton = sandboxButton;

    UILabel *deviceTitle = [self labelWithText:EXLocalizedString(@"common.device")
                                           size:13
                                         weight:UIFontWeightBold
                                          color:[UIColor colorWithWhite:0.62 alpha:1.0]];
    deviceTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [deviceCard addSubview:deviceTitle];
    self.deviceTitleLabel = deviceTitle;

    UILabel *modelKey = [self labelWithText:EXLocalizedString(@"dashboard.model")
                                       size:15
                                     weight:UIFontWeightRegular
                                      color:[UIColor colorWithWhite:0.72 alpha:1.0]];
    UILabel *modelValue = [self labelWithText:@""
                                          size:15
                                        weight:UIFontWeightSemibold
                                         color:UIColor.whiteColor];
    UILabel *iosKey = [self labelWithText:EXLocalizedString(@"dashboard.ios")
                                     size:15
                                   weight:UIFontWeightRegular
                                    color:[UIColor colorWithWhite:0.72 alpha:1.0]];
    UILabel *iosValue = [self labelWithText:@""
                                        size:15
                                      weight:UIFontWeightSemibold
                                       color:UIColor.whiteColor];
    BOOL compatible = [self isCompatibleSystem];
    UILabel *compatibilityKey = [self labelWithText:EXLocalizedString(@"dashboard.patch_compatibility")
                                                size:15
                                              weight:UIFontWeightRegular
                                               color:[UIColor colorWithWhite:0.72 alpha:1.0]];
    UILabel *compatibilityValue = [self labelWithText:compatible ? @"Supported" : @"Unsupported"
                                                  size:15
                                                weight:UIFontWeightBold
                                                 color:compatible
                                                     ? [UIColor colorWithRed:0.25 green:0.90 blue:0.46 alpha:1.0]
                                                     : [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0]];
    UILabel *deviceKey = [self labelWithText:EXLocalizedString(@"dashboard.device_offsets")
                                         size:15
                                       weight:UIFontWeightRegular
                                        color:[UIColor colorWithWhite:0.72 alpha:1.0]];
    UILabel *deviceValue = [self labelWithText:@""
                                           size:15
                                         weight:UIFontWeightBold
                                          color:UIColor.whiteColor];
    UILabel *runtimeKey = [self labelWithText:EXLocalizedString(@"dashboard.exploit_state")
                                          size:15
                                        weight:UIFontWeightRegular
                                         color:[UIColor colorWithWhite:0.72 alpha:1.0]];
    UILabel *runtimeValue = [self labelWithText:@""
                                            size:15
                                          weight:UIFontWeightBold
                                           color:UIColor.whiteColor];
    UILabel *versionKey = [self labelWithText:EXLocalizedString(@"dashboard.external_version")
                                          size:15
                                        weight:UIFontWeightRegular
                                         color:[UIColor colorWithWhite:0.72 alpha:1.0]];
    UILabel *versionValue = [self labelWithText:EXLocalizedString(@"dashboard.external_version_value")
                                            size:15
                                          weight:UIFontWeightBold
                                            color:UIColor.whiteColor];
    NSArray<UILabel *> *deviceKeys = @[modelKey, iosKey, compatibilityKey,
                                       deviceKey, runtimeKey, versionKey];
    NSArray<UILabel *> *deviceValues = @[modelValue, iosValue, compatibilityValue,
                                          deviceValue, runtimeValue, versionValue];
    for (UILabel *label in [deviceKeys arrayByAddingObjectsFromArray:deviceValues]) {
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [deviceCard addSubview:label];
    }
    modelValue.textAlignment = NSTextAlignmentRight;
    iosValue.textAlignment = NSTextAlignmentRight;
    compatibilityValue.textAlignment = NSTextAlignmentRight;
    deviceValue.textAlignment = NSTextAlignmentRight;
    runtimeValue.textAlignment = NSTextAlignmentRight;
    versionValue.textAlignment = NSTextAlignmentRight;
    self.modelValue = modelValue;
    self.iosValue = iosValue;
    self.compatibilityValue = compatibilityValue;
    self.deviceValue = deviceValue;
    self.runtimeValue = runtimeValue;
    self.modelKeyLabel = modelKey;
    self.iosKeyLabel = iosKey;
    self.compatibilityKeyLabel = compatibilityKey;
    self.deviceKeyLabel = deviceKey;
    self.runtimeKeyLabel = runtimeKey;
    self.versionKeyLabel = versionKey;
    self.versionValueLabel = versionValue;
    [NSLayoutConstraint activateConstraints:@[
        [deviceTitle.topAnchor constraintEqualToAnchor:deviceCard.topAnchor constant:12],
        [deviceTitle.leadingAnchor constraintEqualToAnchor:deviceCard.leadingAnchor constant:16],
        [deviceTitle.trailingAnchor constraintEqualToAnchor:deviceCard.trailingAnchor constant:-16],
        [modelKey.topAnchor constraintEqualToAnchor:deviceTitle.bottomAnchor constant:8],
        [modelKey.leadingAnchor constraintEqualToAnchor:deviceTitle.leadingAnchor],
        [modelValue.centerYAnchor constraintEqualToAnchor:modelKey.centerYAnchor],
        [modelValue.leadingAnchor constraintGreaterThanOrEqualToAnchor:modelKey.trailingAnchor constant:8],
        [modelValue.trailingAnchor constraintEqualToAnchor:deviceTitle.trailingAnchor],
        [iosKey.topAnchor constraintEqualToAnchor:modelKey.bottomAnchor constant:7],
        [iosKey.leadingAnchor constraintEqualToAnchor:deviceTitle.leadingAnchor],
        [iosValue.centerYAnchor constraintEqualToAnchor:iosKey.centerYAnchor],
        [iosValue.leadingAnchor constraintGreaterThanOrEqualToAnchor:iosKey.trailingAnchor constant:8],
        [iosValue.trailingAnchor constraintEqualToAnchor:deviceTitle.trailingAnchor],
        [compatibilityKey.topAnchor constraintEqualToAnchor:iosKey.bottomAnchor constant:7],
        [compatibilityKey.leadingAnchor constraintEqualToAnchor:deviceTitle.leadingAnchor],
        [compatibilityValue.centerYAnchor constraintEqualToAnchor:compatibilityKey.centerYAnchor],
        [compatibilityValue.leadingAnchor constraintGreaterThanOrEqualToAnchor:compatibilityKey.trailingAnchor constant:8],
        [compatibilityValue.trailingAnchor constraintEqualToAnchor:deviceTitle.trailingAnchor],
         [deviceKey.topAnchor constraintEqualToAnchor:compatibilityKey.bottomAnchor constant:7],
         [deviceKey.leadingAnchor constraintEqualToAnchor:deviceTitle.leadingAnchor],
         [deviceValue.centerYAnchor constraintEqualToAnchor:deviceKey.centerYAnchor],
         [deviceValue.leadingAnchor constraintGreaterThanOrEqualToAnchor:deviceKey.trailingAnchor constant:8],
         [deviceValue.trailingAnchor constraintEqualToAnchor:deviceTitle.trailingAnchor],
         [runtimeKey.topAnchor constraintEqualToAnchor:deviceKey.bottomAnchor constant:7],
         [runtimeKey.leadingAnchor constraintEqualToAnchor:deviceTitle.leadingAnchor],
         [runtimeValue.centerYAnchor constraintEqualToAnchor:runtimeKey.centerYAnchor],
         [runtimeValue.leadingAnchor constraintGreaterThanOrEqualToAnchor:runtimeKey.trailingAnchor constant:8],
          [runtimeValue.trailingAnchor constraintEqualToAnchor:deviceTitle.trailingAnchor],
          [versionKey.topAnchor constraintEqualToAnchor:runtimeKey.bottomAnchor constant:7],
          [versionKey.leadingAnchor constraintEqualToAnchor:deviceTitle.leadingAnchor],
          [versionValue.centerYAnchor constraintEqualToAnchor:versionKey.centerYAnchor],
          [versionValue.leadingAnchor constraintGreaterThanOrEqualToAnchor:versionKey.trailingAnchor constant:8],
          [versionValue.trailingAnchor constraintEqualToAnchor:deviceTitle.trailingAnchor],
          [versionValue.bottomAnchor constraintEqualToAnchor:sandboxButton.topAnchor constant:-10],
         [sandboxButton.leadingAnchor constraintEqualToAnchor:deviceTitle.leadingAnchor],
         [sandboxButton.trailingAnchor constraintEqualToAnchor:deviceTitle.trailingAnchor],
         [sandboxButton.bottomAnchor constraintEqualToAnchor:deviceCard.bottomAnchor constant:-12],
         [sandboxButton.heightAnchor constraintEqualToConstant:40]
    ]];

    NSMutableArray<NSLayoutConstraint *> *homeConstraints = [NSMutableArray arrayWithArray:@[
        [smallLogo.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:24],
        [smallLogo.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24],
        [smallLogo.widthAnchor constraintEqualToConstant:54],
        [smallLogo.heightAnchor constraintEqualToConstant:54],
        [heading.leadingAnchor constraintEqualToAnchor:smallLogo.trailingAnchor constant:16],
        [heading.centerYAnchor constraintEqualToAnchor:smallLogo.centerYAnchor],
        [hint.topAnchor constraintEqualToAnchor:smallLogo.bottomAnchor constant:34],
        [hint.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24],
        [hint.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24],
         [deviceCard.topAnchor constraintEqualToAnchor:hint.bottomAnchor constant:18],
        [deviceCard.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:24],
        [deviceCard.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-24]
    ]];
    [homeConstraints addObject:
        [deviceCard.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-24]
    ];
    [NSLayoutConstraint activateConstraints:homeConstraints];
     [self refreshHomeStatus];
}

- (BOOL)isCompatibleSystem {
    return [ExternalExploitCompatibility currentStatus].policySupported;
}

- (void)refreshAppearance {
    if (!self.homeMode || !self.isViewLoaded) return;
    UIColor *accent = ExternalAccentColor();
    self.view.tintColor = accent;
    self.navigationController.navigationBar.tintColor = accent;
    self.navigationItem.rightBarButtonItem.tintColor = accent;
    UITabBarController *tabs = self.navigationController.tabBarController;
    tabs.tabBar.tintColor = accent;
    for (UIViewController *controller in tabs.viewControllers) {
        if ([controller isKindOfClass:[UINavigationController class]]) {
            ((UINavigationController *)controller).navigationBar.tintColor = accent;
        }
    }
    self.homeView.tintColor = accent;
    self.sandboxButton.backgroundColor = accent;
    [self refreshHomeStatus];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.homeMode && self.isViewLoaded) {
        [self refreshAppearance];
    }
}

- (void)refreshHomeStatus {
    if (!self.homeMode || !self.modelValue) return;

    ExternalExploitCompatibility *status =
        [ExternalExploitCompatibility currentStatus];
    self.modelValue.text = [NSString stringWithFormat:@"%@ (%@)",
                            status.hardwareName,
                            status.hardwareIdentifier];
    self.modelValue.textColor = ExternalAccentColor();
    self.iosValue.text = [NSString stringWithFormat:@"%@ (%@)",
                          status.osVersion,
                          status.osBuild];
    self.iosValue.textColor = ExternalAccentColor();

    self.compatibilityValue.text = status.policySupported
        ? EXLocalizedString(@"settings.supported")
        : EXLocalizedString(@"settings.unsupported");
    self.compatibilityValue.textColor = status.policySupported
        ? ExternalFixedStatusGreen()
        : [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];

    if (status.simulator) {
        self.deviceValue.text = EXLocalizedString(@"dashboard.simulator_preview");
        self.deviceValue.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    } else if (!status.deviceSupported) {
        self.deviceValue.text = [NSString stringWithFormat:
            EXLocalizedString(@"dashboard.cpu_unavailable"), status.cpuFamilyName];
        self.deviceValue.textColor = [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
    } else if (!status.offsetsAvailable) {
        self.deviceValue.text = [NSString stringWithFormat:
            EXLocalizedString(@"dashboard.offsets_unavailable"), status.cpuFamilyName];
        self.deviceValue.textColor = [UIColor colorWithRed:1.0 green:0.65 blue:0.20 alpha:1.0];
    } else {
        self.deviceValue.text = [NSString stringWithFormat:
            EXLocalizedString(@"dashboard.cpu_ready"), status.cpuFamilyName];
        self.deviceValue.textColor = ExternalFixedStatusGreen();
    }

    ExternalExploitRuntimeState runtimeState =
        ExternalCurrentExploitRuntimeState();
    switch (runtimeState) {
        case ExternalExploitRuntimeStateActive:
            self.runtimeValue.text = EXLocalizedString(@"dashboard.active");
            self.runtimeValue.textColor =
                ExternalFixedStatusGreen();
            break;
        case ExternalExploitRuntimeStateRunning:
            self.runtimeValue.text = EXLocalizedString(@"dashboard.activating");
            self.runtimeValue.textColor =
                ExternalOrangeStatusColor();
            break;
        case ExternalExploitRuntimeStateFailed:
            self.runtimeValue.text = EXLocalizedString(@"dashboard.failed");
            self.runtimeValue.textColor =
                [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
            break;
        case ExternalExploitRuntimeStateUnsupported:
            self.runtimeValue.text = EXLocalizedString(@"settings.unsupported");
            self.runtimeValue.textColor =
                [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
            break;
        case ExternalExploitRuntimeStateNotStarted:
        default:
            self.runtimeValue.text = status.canRun
                 ? EXLocalizedString(@"dashboard.awaiting_activation")
                : EXLocalizedString(@"dashboard.unavailable");
            self.runtimeValue.textColor = status.canRun
                ? [UIColor colorWithWhite:0.72 alpha:1.0]
                : [UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0];
            break;
    }
    BOOL accessActive = [self hasFileAccess];
    self.sandboxButton.enabled = runtimeState != ExternalExploitRuntimeStateRunning && !accessActive;
    self.sandboxButton.backgroundColor = accessActive
        ? ExternalDimmedAccentColor()
        : ExternalAccentColor();
    NSString *accessTitle = accessActive
        ? EXLocalizedString(@"dashboard.access_success")
        : (runtimeState == ExternalExploitRuntimeStateRunning
            ? EXLocalizedString(@"dashboard.access_wait")
            : EXLocalizedString(@"dashboard.access_button"));
    [self.sandboxButton setTitle:accessTitle
                         forState:UIControlStateNormal];
    [self.sandboxButton setTitle:accessTitle
                         forState:UIControlStateDisabled];
}

- (BOOL)hasFileAccess {
    return ExternalSandboxAccessIsActive() || ExternalKernelAccessIsActive();
}

- (void)enableFileAccess {
    if ([self hasFileAccess]) {
        [self addProtectedTabsIfNeeded];
        [self refreshHomeStatus];
        return;
    }
    self.sandboxButton.enabled = NO;
    [self.sandboxButton setTitle:EXLocalizedString(@"dashboard.access_wait")
                         forState:UIControlStateNormal];
    [self.sandboxButton setTitle:EXLocalizedString(@"dashboard.access_wait")
                         forState:UIControlStateDisabled];
    ExternalRunSandboxAccess(^(BOOL success) {
        [self refreshHomeStatus];
        if (success && [self hasFileAccess]) {
            [self addProtectedTabsIfNeeded];
        } else if (!success) {
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:@"File access unavailable"
                                 message:@"The device access attempt failed. Files will continue using the safe container fallback. Relaunch before trying the exploit again."
                          preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}

- (void)addProtectedTabsIfNeeded {
    UITabBarController *tabs = self.navigationController.tabBarController;
    if (!tabs || tabs.viewControllers.count > 1 || ![self hasFileAccess]) return;

    PatchProjectsViewController *patches =
        [[PatchProjectsViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    UINavigationController *patchesNavigationController =
        [[UINavigationController alloc] initWithRootViewController:patches];
    patchesNavigationController.navigationBar.tintColor = ExternalAccentColor();
    patchesNavigationController.tabBarItem = [[UITabBarItem alloc]
        initWithTitle:EXLocalizedString(@"tab.patches")
                   image:[UIImage systemImageNamed:@"syringe.fill"]
                    tag:1];

    CleanerViewController *cleaner =
        [[CleanerViewController alloc] init];
    UINavigationController *cleanerNavigationController =
        [[UINavigationController alloc] initWithRootViewController:cleaner];
    cleanerNavigationController.navigationBar.tintColor = ExternalAccentColor();
    cleanerNavigationController.tabBarItem = [[UITabBarItem alloc]
        initWithTitle:EXLocalizedString(@"tab.cleaner")
                   image:[UIImage systemImageNamed:@"trash.fill"]
                    tag:2];

    UIViewController *home = tabs.viewControllers.firstObject;
    tabs.viewControllers = home
        ? @[home, patchesNavigationController, cleanerNavigationController]
        : @[patchesNavigationController, cleanerNavigationController];
    tabs.selectedIndex = 0;
}

- (void)presentMainTabs {
    UIWindow *window = self.view.window;
    if (!window) {
        id applicationDelegate = UIApplication.sharedApplication.delegate;
        if ([applicationDelegate respondsToSelector:@selector(window)]) {
            window = [applicationDelegate window];
        }
    }
    if (!window) {
        self.pasteKeyButton.enabled = YES;
        self.errorLabel.text = EXLocalizedString(@"login.no_window");
        return;
    }

    ViewController *homeViewController = [[ViewController alloc] initWithHomeMode:YES];
    UINavigationController *homeNavigationController =
        [[UINavigationController alloc]
            initWithRootViewController:homeViewController];
    homeNavigationController.tabBarItem = [[UITabBarItem alloc]
        initWithTitle:EXLocalizedString(@"tab.home")
                   image:[UIImage systemImageNamed:@"house.fill"]
                    tag:0];

    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = @[homeNavigationController];
    tabs.selectedIndex = 0;
    tabs.tabBar.tintColor = ExternalAccentColor();

    window.rootViewController = tabs;
    [window makeKeyAndVisible];
    [homeViewController addProtectedTabsIfNeeded];
}

- (void)openPatches {
    PatchProjectsViewController *patches =
        [[PatchProjectsViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
    UINavigationController *navigationController = [[UINavigationController alloc]
        initWithRootViewController:patches];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    navigationController.navigationBar.prefersLargeTitles = NO;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)openSettings {
    SettingsViewController *settings = [[SettingsViewController alloc] init];
    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:settings];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    navigationController.navigationBar.prefersLargeTitles = NO;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (UILabel *)labelWithText:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    return label;
}

- (UIButton *)filledButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    button.backgroundColor = UIColor.whiteColor;
    button.layer.cornerRadius = 14;
    return button;
}

@end