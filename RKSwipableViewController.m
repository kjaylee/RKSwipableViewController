//
//  RKSwipeBetweenViewControllers.m
//  RKSwipeBetweenViewControllers
//
//  Created by Richard Kim on 7/24/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//
//  @cwRichardKim for regular updates

#import "RKSwipableViewController.h"

#define TAG_BUTTON_INDEX 3000

//%%% customizeable button attributes
CGFloat X_BUFFER = 30.0; //%%% the number of pixels on either side of the segment
CGFloat Y_BUFFER = 14.0; //%%% number of pixels on top of the segment
CGFloat HEIGHT = 30.0; //%%% height of the segment

//%%% customizeable selector bar attributes (the black bar under the buttons)
CGFloat BOUNCE_BUFFER = 10.0; //%%% adds bounce to the selection bar when you scroll
CGFloat ANIMATION_SPEED = 0.2; //%%% the number of seconds it takes to complete the animation
CGFloat SELECTOR_Y_BUFFER = 40.0; //%%% the y-value of the bar that shows what page you are on (0 is the top)
CGFloat SELECTOR_HEIGHT = 4.0; //%%% thickness of the selector bar

CGFloat X_OFFSET = 8.0; //%%% for some reason there's a little bit of a glitchy offset.  I'm going to look for a better workaround in the future

@interface RKSwipableViewController ()

@property (nonatomic) UIScrollView *pageScrollView;
@property (nonatomic) NSInteger currentPageIndex;

@property (nonatomic) BOOL hasAppearedFlag;         //%%% prevents reloading (maintains state)
@end

@implementation RKSwipableViewController
@synthesize selectionBar;
@synthesize pageController;
@synthesize segmentContainerScrollView;
@synthesize buttonTextList;

BOOL doStopSegmentScrolling = NO;
BOOL isPageScrollingFlag = NO;              //%%% prevents scrolling / segment tap crash
bool isSegmentScrolledOverBoundary = NO;    // flag that indicates "over boundary," determines whether scrolling end-to-end or not)

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    isPageScrollingFlag = NO;

    self.navigationBar.barTintColor = [UIColor colorWithRed:0.01 green:0.05 blue:0.06 alpha:1]; //%%% bartint
    self.navigationBar.translucent = NO;
    self.currentPageIndex = 0;
    self.hasAppearedFlag = NO;
    self.enablesScrollingOverEdge = NO;
}

#pragma mark Customizables

//%%% color of the status bar
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
//    return UIStatusBarStyleDefault;
}

//%%% sets up the tabs using a loop.  You can take apart the loop to customize individual buttons, but remember to tag the buttons.  (button.tag=0 and the second button.tag=1, etc)
- (void)setupSegmentButtons {
//    segmentContainerScrollView = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.navigationBar.frame.size.height)];
    segmentContainerScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.navigationBar.frame.size.height)];
    NSInteger numControllers = [self.dataSource numberOfViewControllers:self];
    
    if (!buttonTextList) {
         buttonTextList = [[NSArray alloc] initWithObjects: @"first",@"second",@"third",@"fourth",@"fifth",@"sixth",@"seventh",@"eighth",nil]; //%%%buttontitle
    }

    CGRect baseFrame = CGRectMake(0,0,0,0);
    for (int i=0; i<numControllers; i++) {
        UIButton *button = [[UIButton alloc] init];
//        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+i*(self.view.frame.size.width-2*X_BUFFER)/numControllers-X_OFFSET, Y_BUFFER, (self.view.frame.size.width-2*X_BUFFER)/numControllers, HEIGHT)];
        [segmentContainerScrollView addSubview:button];
        button.tag = [self tagByButtonIndex:i]; //%%% IMPORTANT: if you make your own custom buttons, you have to tag them appropriately
        button.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];//%%% buttoncolors
        
        [button addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:[buttonTextList objectAtIndex:i] forState:UIControlStateNormal]; //%%%buttontitle
        CGSize fitSize = [button sizeThatFits:self.view.frame.size];
        baseFrame.size = fitSize;
        [button setFrame:baseFrame];
        baseFrame.origin.x += fitSize.width ;
        if(i < numControllers - 1)
            baseFrame.origin.x += X_BUFFER;
    }
//    baseFrame = CGRectMake(0, 0, baseFrame.origin.x, self.navigationBar.frame.size.height);
    segmentContainerScrollView.contentSize = CGSizeMake(baseFrame.origin.x, self.navigationBar.frame.size.height);
    segmentContainerScrollView.scrollEnabled = YES;
    segmentContainerScrollView.scrollsToTop = NO;
    segmentContainerScrollView.showsHorizontalScrollIndicator = NO;
    segmentContainerScrollView.showsVerticalScrollIndicator = NO;
    segmentContainerScrollView.alwaysBounceVertical = NO;
    segmentContainerScrollView.minimumZoomScale = 1;
    segmentContainerScrollView.maximumZoomScale = 1;
    segmentContainerScrollView.clipsToBounds = NO;

    pageController.navigationController.navigationBar.topItem.titleView = segmentContainerScrollView;
    
    //%%% example custom buttons example:
    /*
    NSInteger width = (self.view.frame.size.width-(2*X_BUFFER))/3;
    UIButton *leftButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER, Y_BUFFER, width, HEIGHT)];
    UIButton *middleButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+width, Y_BUFFER, width, HEIGHT)];
    UIButton *rightButton = [[UIButton alloc]initWithFrame:CGRectMake(X_BUFFER+2*width, Y_BUFFER, width, HEIGHT)];
    
    [self.navigationBar addSubview:leftButton];
    [self.navigationBar addSubview:middleButton];
    [self.navigationBar addSubview:rightButton];
    
    leftButton.tag = 0;
    middleButton.tag = 1;
    rightButton.tag = 2;
    
    leftButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
    middleButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
    rightButton.backgroundColor = [UIColor colorWithRed:0.03 green:0.07 blue:0.08 alpha:1];
    
    [leftButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [middleButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [leftButton setTitle:@"left" forState:UIControlStateNormal];
    [middleButton setTitle:@"middle" forState:UIControlStateNormal];
    [rightButton setTitle:@"right" forState:UIControlStateNormal];
     */
    
    [self setupSelector];
}


//%%% sets up the selection bar under the buttons on the navigation bar
- (void)setupSelector {
//    selectionBar = [[UIView alloc] initWithFrame:CGRectMake(X_BUFFER-X_OFFSET, SELECTOR_Y_BUFFER,(self.view.frame.size.width-2*X_BUFFER)/[viewControllerArray count], SELECTOR_HEIGHT)];
    UIView *firstButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:0]];
    selectionBar = [[UIView alloc] initWithFrame:CGRectMake(0,SELECTOR_Y_BUFFER,firstButton.frame.size.width,SELECTOR_HEIGHT)];
    selectionBar.backgroundColor = [UIColor greenColor]; //%%% sbcolor
    selectionBar.alpha = 0.8; //%%% sbalpha
    [segmentContainerScrollView addSubview:selectionBar];
}

- (long)tagByButtonIndex:(long)buttonIndex {
    if(buttonIndex < 0)
        return TAG_BUTTON_INDEX + buttonIndex + [self.dataSource numberOfViewControllers:self];
    else
        return TAG_BUTTON_INDEX + buttonIndex;
}

- (int)buttonIndexByTag:(int)tag {
    return tag - TAG_BUTTON_INDEX;
}

//generally, this shouldn't be changed unless you know what you're changing
#pragma mark Setup

- (void)viewWillAppear:(BOOL)animated {
    if (!self.hasAppearedFlag) {
        [self setupPageViewController];
        [self setupSegmentButtons];
        self.hasAppearedFlag = YES;
    }
}

//%%% generic setup stuff for a pageview controller.  Sets up the scrolling style and delegate for the controller
- (void)setupPageViewController {
    pageController = (UIPageViewController*)self.topViewController;
    pageController.delegate = self;
    pageController.dataSource = self;
    UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:0];
    [pageController setViewControllers:@[vcToBeShown] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    [self syncScrollView];
}

//%%% this allows us to get information back from the scrollview, namely the coordinate information that we can link to the selection bar.
- (void)syncScrollView {
    for (UIView* view in pageController.view.subviews){
        if([view isKindOfClass:[UIScrollView class]]) {
            self.pageScrollView = (UIScrollView *)view;
            self.pageScrollView.delegate = self;
        }
    }
}

//%%% methods called when you tap a button or scroll through the pages
// generally shouldn't touch this unless you know what you're doing or
// have a particular performance thing in mind

#pragma mark Movement

//%%% when you tap one of the buttons, it shows that page,
//but it also has to animate the other pages to make it feel like you're crossing a 2d expansion,
//so there's a loop that shows every view controller in the array up to the one you selected
//eg: if you're on page 1 and you click tab 3, then it shows you page 2 and then page 3
- (void)tapSegmentButtonAction:(UIButton *)button {
    if (!isPageScrollingFlag) {
        NSInteger currentButtonTag = [self tagByButtonIndex:self.currentPageIndex];
        __weak typeof(self) weakSelf = self;
        //%%% check to see if you're going left -> right or right -> left
        if (button.tag > currentButtonTag) {
            doStopSegmentScrolling = YES;
            //%%% scroll through all the objects between the two points
            for (int tag = (int)currentButtonTag+1; tag<=button.tag; tag++) {
                int buttonIndex = [self buttonIndexByTag:tag];
                UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:buttonIndex];
                [pageController setViewControllers:@[vcToBeShown]
                                         direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL complete)
                {
                    //%%% if the action finishes scrolling (i.e. the user doesn't stop it in the middle),
                    //then it updates the page that it's currently on
                    if (complete) {
                        [weakSelf updateCurrentPageIndex:buttonIndex];
                        if(tag == button.tag)
                            doStopSegmentScrolling = NO;
                    }
                }];
            }
        }
        
        //%%% this is the same thing but for going right -> left
        else if (button.tag < currentButtonTag) {
            doStopSegmentScrolling = YES;
            for (int tag = (int)currentButtonTag-1; tag >= button.tag; tag--) {
                int buttonIndex = [self buttonIndexByTag:tag];
                UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:buttonIndex];
                [pageController setViewControllers:@[vcToBeShown] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL complete){
                    if (complete) {
                        [weakSelf updateCurrentPageIndex:buttonIndex];
                        if(tag == button.tag)
                            doStopSegmentScrolling = NO;
                    }
                }];
            }
        }
    }
}

//%%% makes sure the nav bar is always aware of what page you're on
//in reference to the array of view controllers you gave
- (void)updateCurrentPageIndex:(int)newIndex {
    self.currentPageIndex = newIndex;
}

//%%% method is called when any of the pages moves.
//It extracts the xcoordinate from the center point and instructs the selection bar to move accordingly
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat xFromCenter = self.view.frame.size.width - scrollView.contentOffset.x; //%%% positive for right swipe, negative for left
    CGFloat ratio = -1 * xFromCenter / self.view.frame.size.width;
    CGFloat absRatio = fabs(xFromCenter / self.view.frame.size.width);
    UIView *selectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:self.currentPageIndex]];
    UIView *maybeSelectedButton = selectedButton;
    long vcCount = [self.dataSource numberOfViewControllers:self];
    NSAssert(0 <= self.currentPageIndex && self.currentPageIndex < vcCount, @"currentPageIndex over boundary: %ld", self.currentPageIndex);
    CGRect buttonFrame = selectedButton.frame;
    CGRect selectionBarFrame = selectionBar.frame;
    selectionBarFrame.origin.x = buttonFrame.origin.x;
    if(ratio < 0 && self.currentPageIndex == 0) {
        // over to left
        if(isSegmentScrolledOverBoundary) {
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:(vcCount-1)]];
            selectionBarFrame.origin.x = selectedButton.frame.origin.x + pow(absRatio,2) * (maybeSelectedButton.frame.origin.x);
        } else {
            selectionBarFrame.origin.x += absRatio * (-buttonFrame.size.width);
        }
    } else if(ratio > 0 && self.currentPageIndex == vcCount-1) {
        // over to right
        if(isSegmentScrolledOverBoundary) {
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:0]];
            selectionBarFrame.origin.x = selectedButton.frame.origin.x - (pow(absRatio,2) * selectedButton.frame.origin.x);
        } else {
            selectionBarFrame.origin.x += absRatio * (buttonFrame.size.width);
        }
    } else {
        if(ratio > 0)
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:self.currentPageIndex + 1]];
        if(ratio < 0)
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:self.currentPageIndex - 1]];
        selectionBarFrame.origin.x += absRatio * (maybeSelectedButton.frame.origin.x - buttonFrame.origin.x);
    }
    selectionBarFrame.size.width = (1-absRatio) * buttonFrame.size.width + absRatio * maybeSelectedButton.frame.size.width;
    selectionBar.frame = selectionBarFrame;
//    //%%% checks to see what page you are on and adjusts the xCoor accordingly.
//    //i.e. if you're on the second page, it makes sure that the bar starts from the frame.origin.x of the
//    //second tab instead of the beginning
//    NSInteger xCoor = X_BUFFER+selectionBar.frame.size.width*self.currentPageIndex-X_OFFSET;
//    
//    selectionBar.frame = CGRectMake(xCoor-xFromCenter/[viewControllerArray count], selectionBar.frame.origin.y, selectionBar.frame.size.width, selectionBar.frame.size.height);

    // Forcely scrolls segment container(=menu bar) according to selectionBar's frame.
    if(!doStopSegmentScrolling) {
        CGPoint contentOffset = self.segmentContainerScrollView.contentOffset;
        CGRect scrollViewFrame = self.segmentContainerScrollView.frame;
        float leftX = selectionBarFrame.origin.x;
        float rightX = selectionBarFrame.origin.x + selectionBarFrame.size.width;
        // scroll to left
        if(leftX < contentOffset.x) {
            if(leftX < 0)
                contentOffset.x = 0;
            else
                contentOffset.x = leftX;
            self.segmentContainerScrollView.contentOffset = contentOffset;
        }
        // scroll to right
        if(rightX > contentOffset.x + scrollViewFrame.size.width) {
            if(rightX > self.segmentContainerScrollView.contentSize.width) {
                contentOffset.x = self.segmentContainerScrollView.contentSize.width - scrollViewFrame.size.width;
            }
            else {
                contentOffset.x = selectionBarFrame.origin.x + selectionBarFrame.size.width - scrollViewFrame.size.width;
            }
            self.segmentContainerScrollView.contentOffset = contentOffset;
        }
    }
}


//%%% the delegate functions for UIPageViewController.
//Pretty standard, but generally, don't touch this.
#pragma mark UIPageViewController Delegate Functions

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Page View Controller Data Source
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    long vcCount = [self.dataSource numberOfViewControllers:self];
    long index = [self.dataSource swipableViewController:self indexOfViewController:viewController];
    if (index == 0) {
        if (self.enablesScrollingOverEdge)
            return [self.dataSource swipableViewController:self viewControllerAt:vcCount - 1];
        else
            return nil;
    }
    return [self.dataSource swipableViewController:self viewControllerAt:index - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    long vcCount = [self.dataSource numberOfViewControllers:self];
    long index = [self.dataSource swipableViewController:self indexOfViewController:viewController];
    if (index == vcCount - 1) {
        if (self.enablesScrollingOverEdge)
            return [self.dataSource swipableViewController:self viewControllerAt:0];
        else
            return nil;
    }
    return [self.dataSource swipableViewController:self viewControllerAt:index + 1];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        UIViewController *shownVC = [pageViewController.viewControllers lastObject];
        self.currentPageIndex = [self.dataSource swipableViewController:self indexOfViewController:shownVC];
    }
}

#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    isPageScrollingFlag = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0) {
    long vcCount = [self.dataSource numberOfViewControllers:self];
    UIView *scrollTargetButton = nil;
    UIView *scrollSourceButton = nil;
    // to left at first page
    if(targetContentOffset->x == 0 && self.currentPageIndex == 0) {
        scrollSourceButton = [segmentContainerScrollView viewWithTag:[self tagByButtonIndex:0]];
        scrollTargetButton = [segmentContainerScrollView viewWithTag:[self tagByButtonIndex:(vcCount-1)]];
    }
    // to right at last page
    if(targetContentOffset->x >= scrollView.frame.size.width*1.5 && self.currentPageIndex == (vcCount-1)) {
        scrollSourceButton = [segmentContainerScrollView viewWithTag:[self tagByButtonIndex:(vcCount-1)]];
        scrollTargetButton = [segmentContainerScrollView viewWithTag:[self tagByButtonIndex:0]];
    }
    if(scrollSourceButton && scrollTargetButton) {
        isSegmentScrolledOverBoundary = YES;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    isPageScrollingFlag = NO;
    isSegmentScrolledOverBoundary = NO;
    doStopSegmentScrolling = NO;
}

@end
