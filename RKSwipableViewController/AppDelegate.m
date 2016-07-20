//
//  AppDelegate.m
//  RKSwipableViewController
//
//  Created by Richard Kim on 7/24/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//
//  Modified by Kenial Lee on 7/17/16


#import "AppDelegate.h"

#import "RKSwipableViewController.h"

@interface AppDelegate () <RKSwipableViewControllerDataSource>
@end

@implementation AppDelegate

NSMutableArray *_vcArray;
NSArray *_vcMenuTitles;
#define NUMBER_OF_SWIPABLE_VIEWS 8

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];

    _vcArray = [[NSMutableArray alloc] init];
    for(int i=0; i<NUMBER_OF_SWIPABLE_VIEWS; i++) {
        [_vcArray addObject:[NSNull null]];
    }
    _vcMenuTitles = [[NSArray alloc] initWithObjects: @"first",@"second",@"third",@"fourth",@"fifth",@"sixth",@"seventh",@"eighth",nil];

    RKSwipableViewController *swipableVC = [[RKSwipableViewController alloc] init];
    // customizing things
    swipableVC.isSegmentSizeFixed = NO;
    swipableVC.segmentButtonMinimumWidth = 50.0f;
    swipableVC.segmentButtonMarginWidth = 25.0f;
    swipableVC.segmentButtonEdgeMarginWidth = 10.0f;
    swipableVC.shouldSelectedButtonCentered = YES;
    swipableVC.segmentButtonHeight = 44.0f;
    swipableVC.segmentButtonBackgroundColor = [UIColor colorWithRed:0 green:0.4 blue:0.7 alpha:1];
    swipableVC.segmentButtonTextColor = [UIColor whiteColor];
    swipableVC.selectionBarColor = [UIColor greenColor];
    swipableVC.segmentContainerScrollViewBackgroundColor = [UIColor colorWithRed:0 green:0.4 blue:0.7 alpha:1];
    swipableVC.dataSource = self;
    swipableVC.enablesScrollingOverEdge = YES;
    swipableVC.isScrolledWhenTapSegment = YES;
    swipableVC.doUpdateNavigationTitleWithSwipedViewController = YES;

    self.window.rootViewController = swipableVC;
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - RKSwipableViewControllerDataSource
- (long)numberOfViewControllers:(RKSwipableViewController *)swipableViewController {
    return NUMBER_OF_SWIPABLE_VIEWS;
}

- (UIViewController *)swipableViewController:(RKSwipableViewController *)swipableViewController viewControllerAt:(long)index {
    // VC source should be initialized before execution path arrives at here.
    if(_vcArray[index] == [NSNull null]) {
        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor colorWithWhite:1.0 - (index/16.0) alpha:1];
        _vcArray[index] = vc;
        UILabel *label = [[UILabel alloc] initWithFrame:swipableViewController.view.frame];
        label.text = _vcMenuTitles[index];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:36];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [vc.view addSubview:label];
        vc.title = label.text;

        if(index == 0) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            button.frame = CGRectMake(0, 0, 200, 80);
            [button setTitle:@"Push VC into navigation" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
            CGPoint center = CGPointMake(swipableViewController.view.frame.size.width/2, swipableViewController.view.frame.size.height/2+50);
            button.center = center;
            [vc.view addSubview:button];
        }
    }
    return _vcArray[index];
}

- (long)swipableViewController:(RKSwipableViewController *)swipableViewController indexOfViewController:(UIViewController *)viewController {
    for(long i=0; i<_vcArray.count; i++) {
        if(_vcArray[i] == viewController)
            return i;
    }
    return NSNotFound;
}

- (NSString *)swipableViewController:(RKSwipableViewController *)swipableViewController segmentTextAt:(long)index {
    return _vcMenuTitles[index];
}

#pragma mark
- (IBAction)tappedButton:(UIButton *)button {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:1];
    vc.title = @"Pushed VC";
    UINavigationController *nvc = self.window.rootViewController;
    [nvc pushViewController:vc animated:YES];
}

@end
