#import "SCISettingsViewController.h"

static char rowStaticRef[] = "row";

@interface SCISettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;

@end

///

@implementation SCISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    
    if (self) {
        self.title = title;
        self.reduceMargin = reduceMargin;
        
        // Exclude development cells from release builds
        NSMutableArray *mutableSections = [sections mutableCopy];
        
        [mutableSections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *section, NSUInteger index, BOOL *stop) {
        
            if ([section[@"header"] hasPrefix:@"_"] && [section[@"footer"] hasPrefix:@"_"]) {
                if (![[SCIUtils IGVersionString] isEqualToString:@"0.0.0"]) {
                    [mutableSections removeObjectAtIndex:index];
                }
            }

            else if ([section[@"header"] isEqualToString:@"Experimental"]) {
                if (![[SCIUtils IGVersionString] hasSuffix:@"-dev"]) {
                    [mutableSections removeObjectAtIndex:index];
                }
            }
            
        }];
        
        self.sections = [mutableSections copy];
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithTitle:[SCITweakSettings title] sections:[SCITweakSettings sections] reduceMargin:YES];
}

// MARK: - Monochrome Luxury Header View

- (UIView *)buildMonochromeHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 130)];
    headerView.backgroundColor = [UIColor clearColor];

    // Card background
    UIView *card = [[UIView alloc] init];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
            ? [UIColor colorWithWhite:0.12 alpha:1.0]
            : [UIColor colorWithWhite:0.96 alpha:1.0];
    }];
    card.layer.cornerRadius = 16.0;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 0.5;
    card.layer.borderColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
            ? [UIColor colorWithWhite:0.25 alpha:1.0]
            : [UIColor colorWithWhite:0.85 alpha:1.0];
    }].CGColor;
    card.clipsToBounds = YES;
    [headerView addSubview:card];

    // Icon Container
    UIView *iconBox = [[UIView alloc] init];
    iconBox.translatesAutoresizingMaskIntoConstraints = NO;
    iconBox.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
            ? [UIColor whiteColor]
            : [UIColor blackColor];
    }];
    iconBox.layer.cornerRadius = 12.0;
    iconBox.layer.cornerCurve = kCACornerCurveContinuous;
    [card addSubview:iconBox];

    // Icon Image
    UIImageView *iconImageView = [[UIImageView alloc] init];
    iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *symCfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold];
    iconImageView.image = [UIImage systemImageNamed:@"sparkles" withConfiguration:symCfg];
    iconImageView.tintColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
            ? [UIColor blackColor]
            : [UIColor whiteColor];
    }];
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [iconBox addSubview:iconImageView];

    // Title Label
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"DOPARESET";
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor labelColor];
    [card addSubview:titleLabel];

    // Subtitle Label
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.text = @"Dopamine-free Instagram experience";
    subtitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    subtitleLabel.textColor = [UIColor secondaryLabelColor];
    [card addSubview:subtitleLabel];

    // Version Pill Badge
    UIView *pill = [[UIView alloc] init];
    pill.translatesAutoresizingMaskIntoConstraints = NO;
    pill.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
            ? [UIColor colorWithWhite:0.22 alpha:1.0]
            : [UIColor colorWithWhite:0.88 alpha:1.0];
    }];
    pill.layer.cornerRadius = 10.0;
    pill.clipsToBounds = YES;
    [card addSubview:pill];

    UILabel *pillLabel = [[UILabel alloc] init];
    pillLabel.translatesAutoresizingMaskIntoConstraints = NO;
    pillLabel.text = SCIVersionString;
    pillLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
    pillLabel.textColor = [UIColor labelColor];
    [pill addSubview:pillLabel];

    // Layout Constraints
    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:headerView.topAnchor constant:12],
        [card.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:16],
        [card.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-16],
        [card.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor constant:-8],

        [iconBox.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [iconBox.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [iconBox.widthAnchor constraintEqualToConstant:46],
        [iconBox.heightAnchor constraintEqualToConstant:46],

        [iconImageView.centerXAnchor constraintEqualToAnchor:iconBox.centerXAnchor],
        [iconImageView.centerYAnchor constraintEqualToAnchor:iconBox.centerYAnchor],

        [titleLabel.leadingAnchor constraintEqualToAnchor:iconBox.trailingAnchor constant:12],
        [titleLabel.topAnchor constraintEqualToAnchor:iconBox.topAnchor constant:3],

        [subtitleLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [subtitleLabel.bottomAnchor constraintEqualToAnchor:iconBox.bottomAnchor constant:-3],

        [pill.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14],
        [pill.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
        [pill.heightAnchor constraintEqualToConstant:20],

        [pillLabel.leadingAnchor constraintEqualToAnchor:pill.leadingAnchor constant:7],
        [pillLabel.trailingAnchor constraintEqualToAnchor:pill.trailingAnchor constant:-7],
        [pillLabel.centerYAnchor constraintEqualToAnchor:pill.centerYAnchor]
    ]];

    return headerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    // Attach custom header only on root settings page
    if ([self.title isEqualToString:[SCITweakSettings title]]) {
        self.tableView.tableHeaderView = [self buildMonochromeHeaderView];
    }

    [self.view addSubview:self.tableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"SCInstaFirstRun"] isEqualToString:SCIVersionString]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"DopaReset Settings Info"
                                                                       message:@"In the future: Hold down on the three lines at the top right of your profile page, to re-open DopaReset settings."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"I understand!"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        
        UIViewController *presenter = self.presentingViewController;
        [presenter presentViewController:alert animated:YES completion:nil];
        
        // Done with first-time setup for this version
        [[NSUserDefaults standardUserDefaults] setValue:SCIVersionString forKey:@"SCInstaFirstRun"];
    }
}

// Helper to generate square/squircle monochrome icon backgrounds
- (UIImage *)monochromeIconImageForSymbol:(SCISymbol *)symbol {
    CGSize boxSize = CGSizeMake(28, 28);
    UIGraphicsBeginImageContextWithOptions(boxSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Squircle path
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 28, 28) cornerRadius:7.0];
    
    // Background color: monochrome dark grey / subtle light grey
    UIColor *bgColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
            ? [UIColor colorWithWhite:0.22 alpha:1.0]
            : [UIColor colorWithWhite:0.88 alpha:1.0];
    }];
    CGContextSetFillColorWithColor(context, bgColor.CGColor);
    [path fill];

    // Symbol drawing centered
    UIImage *sym = [symbol image];
    if (sym) {
        UIColor *fgColor = [UIColor labelColor];
        sym = [sym imageWithTintColor:fgColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        CGFloat symW = sym.size.width;
        CGFloat symH = sym.size.height;
        CGRect symRect = CGRectMake((28 - symW) / 2.0, (28 - symH) / 2.0, symW, symH);
        [sym drawInRect:symRect];
    }

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

// MARK: - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (!row) return nil;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UIListContentConfiguration *cellContentConfig = cell.defaultContentConfiguration;
    
    cellContentConfig.text = row.title;
    
    // Subtitle
    if (row.subtitle.length) {
        cellContentConfig.secondaryText = row.subtitle;
        cellContentConfig.textToSecondaryTextVerticalPadding = 4.5;
    }
    
    // Icon (Monochrome squircle box)
    if (row.icon != nil) {
        cellContentConfig.image = [self monochromeIconImageForSymbol:row.icon];
    }
    
    // Image url
    if (row.imageUrl != nil) {
        [self loadImageFromURL:row.imageUrl atIndexPath:indexPath forTableView:tableView];
        cellContentConfig.imageToTextPadding = 14;
    }
    
    switch (row.type) {
        case SCITableCellStatic: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellLink: {
            cellContentConfig.textProperties.color = [UIColor labelColor];
            cellContentConfig.textProperties.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize
                                                                      weight:UIFontWeightMedium];
            
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.right"]];
            imageView.tintColor = [UIColor secondaryLabelColor];
            cell.accessoryView = imageView;
            
            break;
        }
            
        case SCITableCellSwitch: {
            UISwitch *toggle = [UISwitch new];
            toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:row.defaultsKey];
            toggle.onTintColor = [SCIUtils SCIColor_Primary];
            [self updateSwitchAppearance:toggle];
            
            objc_setAssociatedObject(toggle, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = toggle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellStepper: {
            UIStepper *stepper = [UIStepper new];
            stepper.minimumValue = row.min;
            stepper.maximumValue = row.max;
            stepper.stepValue = row.step;
            stepper.value = [[NSUserDefaults standardUserDefaults] doubleForKey:row.defaultsKey];
            
            objc_setAssociatedObject(stepper, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [stepper addTarget:self
                        action:@selector(stepperChanged:)
              forControlEvents:UIControlEventValueChanged];
            
            if (row.subtitle.length) {
                cellContentConfig.secondaryText = [self formatString:row.subtitle withValue:stepper.value label:row.label singularLabel:row.singularLabel];
            }
            
            cell.accessoryView = stepper;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellButton: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
            
        case SCITableCellMenu: {
            UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [menuButton setTitle:@"•••" forState:UIControlStateNormal];
            menuButton.menu = [row menuForButton:menuButton];
            menuButton.showsMenuAsPrimaryAction = YES;
            menuButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize
                                                           weight:UIFontWeightMedium];
            
            UIButtonConfiguration *config = menuButton.configuration ?: [UIButtonConfiguration plainButtonConfiguration];
            menuButton.configuration.contentInsets = NSDirectionalEdgeInsetsMake(8, 8, 8, 8);
            menuButton.configuration = config;

            [menuButton sizeToFit];
            
            cell.accessoryView = menuButton;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case SCITableCellNavigation: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }
    
    cell.contentConfiguration = cellContentConfig;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.sections[section][@"footer"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SCISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (!row) return;

    if (row.type == SCITableCellLink) {
        [[UIApplication sharedApplication] openURL:row.url options:@{} completionHandler:nil];
    }
    else if (row.type == SCITableCellButton) {
        if (row.action != nil) {
            row.action();
        }
    }
    else if (row.type == SCITableCellNavigation) {
        if (row.navSections.count > 0) {
            UIViewController *vc = [[SCISettingsViewController alloc] initWithTitle:row.title sections:row.navSections reduceMargin:NO];
            vc.title = row.title;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (row.navViewController) {
            [self.navigationController pushViewController:row.navViewController animated:YES];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)updateSwitchAppearance:(UISwitch *)toggle {
    if (toggle.isOn) {
        toggle.thumbTintColor = [UIColor whiteColor];
    } else {
        toggle.thumbTintColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
            return (tc.userInterfaceStyle == UIUserInterfaceStyleDark)
                ? [UIColor colorWithWhite:0.48 alpha:1.0]
                : [UIColor colorWithWhite:0.75 alpha:1.0];
        }];
    }
}

// MARK: - Actions

- (void)switchChanged:(UISwitch *)sender {
    [self updateSwitchAppearance:sender];
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    
    NSLog(@"Switch changed: %@", sender.isOn ? @"ON" : @"OFF");
    
    if (row.requiresRestart) {
        [SCIUtils showRestartConfirmation];
    }
}

- (void)stepperChanged:(UIStepper *)sender {
    SCISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setDouble:sender.value forKey:row.defaultsKey];
    
    NSLog(@"Stepper changed: %f", sender.value);
    
    [self reloadCellForView:sender];
}

- (void)menuChanged:(UICommand *)command {
    NSDictionary *properties = command.propertyList;
    
    [[NSUserDefaults standardUserDefaults] setValue:properties[@"value"] forKey:properties[@"defaultsKey"]];
    
    NSLog(@"Menu changed: %@", command.propertyList[@"value"]);
    
    [self reloadCellForView:command.sender animated:YES];
    
    if (properties[@"requiresRestart"]) {
        [SCIUtils showRestartConfirmation];
    }
}

// MARK: - Helper

- (NSString *)formatString:(NSString *)template withValue:(double)value label:(NSString *)label singularLabel:(NSString *)singularLabel {
    NSString *applicableLabel = fabs(value - 1.0) < 0.00001 ? singularLabel : label;
    
    if (fabs(value) < 0.00001) {
        value = 0.0;
    }

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = [SCIUtils decimalPlacesInDouble:value];

    NSString *stringValue = [formatter stringFromNumber:@(value)];

    return [NSString stringWithFormat:template, stringValue, applicableLabel];
}

- (void)reloadCellForView:(UIView *)view animated:(BOOL)animated {
    UITableViewCell *cell = (UITableViewCell *)view.superview;
    while (cell && ![cell isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *)cell.superview;
    }
    if (!cell) return;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) return;
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
}
- (void)reloadCellForView:(UIView *)view {
    [self reloadCellForView:view animated:NO];
}

- (void)loadImageFromURL:(NSURL *)url atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    if (!url) return;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (!data || error) return;

        UIImage *image = [UIImage imageWithData:data];
        if (!image) return;

        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (!cell) return;

            UIListContentConfiguration *config = (UIListContentConfiguration *)cell.contentConfiguration;
            config.image = image;
            config.imageProperties.maximumSize = CGSizeMake(36, 36);
            config.imageProperties.cornerRadius = 18.0;
            cell.contentConfiguration = config;
        });
    }];

    [task resume];
}

@end
