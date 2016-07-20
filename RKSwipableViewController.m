//
//  RKSwipableViewController.m
//  RKSwipableViewController
//
//  Created by Richard Kim on 7/24/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//
//  @cwRichardKim for regular updates

#import "RKSwipableViewController.h"
#import <objc/runtime.h>

#define TAG_BUTTON_INDEX 3000

//%%% customizeable button attributes
CGFloat X_BUFFER = 30.0; //%%% the number of pixels on either side of the segment
CGFloat Y_BUFFER = 14.0; //%%% number of pixels on top of the segment
CGFloat HEIGHT = 30.0; //%%% height of the segment

//%%% customizeable selector bar attributes (the black bar under the buttons)
CGFloat BOUNCE_BUFFER = 10.0; //%%% adds bounce to the selection bar when you scroll
CGFloat ANIMATION_SPEED = 0.2; //%%% the number of seconds it takes to complete the animation
CGFloat SELECTOR_HEIGHT = 4.0; //%%% thickness of the selector bar

CGFloat X_OFFSET = 8.0; //%%% for some reason there's a little bit of a glitchy offset.  I'm going to look for a better workaround in the future

@interface RKSwipableViewController ()

@property (nonatomic) UIScrollView *pageScrollView;
@property (nonatomic) long currentPageIndex;

@property (nonatomic) BOOL hasAppearedFlag;         //%%% prevents reloading (maintains state)
@end

@implementation RKSwipableViewController
@synthesize selectionBar;
@synthesize pageController = _pageController;
@synthesize segmentContainerScrollView;
@synthesize currentPageIndex = _currentPageIndex;
@synthesize swipableViewControllers = _swipableViewControllers;

BOOL doStopSegmentScrolling = NO;
BOOL isPageScrollingFlag = NO;              //%%% prevents scrolling / segment tap crash
bool isSegmentScrolledOverBoundary = NO;    // flag that indicates "over boundary," determines whether scrolling end-to-end or not)

#pragma mark Properties
- (NSMutableArray *)swipableViewControllers {
    if(_swipableViewControllers == nil)
        _swipableViewControllers = [[NSMutableArray alloc] init];
    long numberofVC = [self.dataSource numberOfViewControllers:self];
    while(_swipableViewControllers.count < numberofVC) {
        [_swipableViewControllers addObject:[NSNull null]];
    }
    return _swipableViewControllers;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        [self initialize];
    }
    return self;
}

// for revived from storyboard
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.enablesScrollingOverEdge = NO;
    self.isScrolledWhenTapSegment = NO;
    self.isSegmentSizeFixed = NO;
    self.shouldSelectedButtonCentered = NO;
    self.segmentButtonHeight = 44.0f;
    self.segmentButtonMarginWidth = 10.0f;
    self.segmentButtonEdgeMarginWidth = 5.0f;
    self.doUpdateNavigationTitleWithSwipedViewController = NO;
    UIPageViewController *pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                           navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                         options:nil];
    _pageController = pageController;
    [self setViewControllers:@[pageController]];
    isPageScrollingFlag = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.navigationBar.barTintColor = [UIColor colorWithRed:0.01 green:0.05 blue:0.06 alpha:1]; //%%% bartint
//    self.navigationBar.translucent = NO;
    self.hasAppearedFlag = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.hasAppearedFlag) {
        [self setupPageViewController];
        [self setupSegmentButtons];
        [self syncScrollView];
        self.hasAppearedFlag = YES;
        self.currentPageIndex = 0;
        UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:_currentPageIndex];
        [_pageController setViewControllers:@[vcToBeShown]
                                  direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setupConstraints];

    // workaround: prevent from crashing on iOS 7
    [self.view layoutIfNeeded];
}


#pragma mark Customizables

//%%% color of the status bar
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
//    return UIStatusBarStyleDefault;
}

//%%% sets up the tabs using a loop.  You can take apart the loop to customize individual buttons, but remember to tag the buttons.  (button.tag=0 and the second button.tag=1, etc)
- (void)setupSegmentButtons {
    // set sizes of segment container & swipable area (by UIPageController)
    CGRect segmentBounds = CGRectMake(0,
                                      -self.segmentButtonHeight,
                                      self.view.frame.size.width,
                                      self.segmentButtonHeight);
    segmentContainerScrollView = [[UIScrollView alloc] initWithFrame:segmentBounds];
    NSInteger numControllers = [self.dataSource numberOfViewControllers:self];
    NSAssert([self.dataSource respondsToSelector:@selector(swipableViewController:segmentTextAt:)] ||
             [self.dataSource respondsToSelector:@selector(swipableViewController:segmentButtonAt:)],
             @"RKSwipableViewControllerDataSource should return texts of segments or buttons");
    CGRect baseFrame = CGRectMake(self.segmentButtonEdgeMarginWidth,0,0,0);
    for (int i=0; i<numControllers; i++) {
        if([self.dataSource respondsToSelector:@selector(swipableViewController:segmentTextAt:)]) {
            NSString *segmentTitle = [self.dataSource swipableViewController:self segmentTextAt:i];
            UIButton *button = [[UIButton alloc] init];
            button.tag = [self tagByButtonIndex:i]; //%%% IMPORTANT: if you make your own custom buttons, you have to tag them appropriately
            button.backgroundColor = self.segmentButtonBackgroundColor;
            [button setTitleColor:self.segmentButtonTextColor forState:UIControlStateNormal];
            [button setTitleColor:self.selectionBarColor forState:UIControlStateSelected];
            [button addTarget:self action:@selector(tapSegmentButton:) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:segmentTitle forState:UIControlStateNormal]; //%%%buttontitle
            button.titleLabel.font = [UIFont systemFontOfSize:15];
            CGSize fitSize = [button sizeThatFits:segmentBounds.size];
            if(self.isSegmentSizeFixed) {
                fitSize.width = self.segmentButtonWidth;
            } else {
                if(fitSize.width < self.segmentButtonMinimumWidth)
                    fitSize.width = self.segmentButtonMinimumWidth;
            }
            baseFrame.size = fitSize;
            baseFrame.origin.y = (segmentContainerScrollView.frame.size.height - fitSize.height - SELECTOR_HEIGHT) / 2;
            [button setFrame:baseFrame];
            baseFrame.origin.x += fitSize.width + self.segmentButtonMarginWidth;
            [segmentContainerScrollView addSubview:button];
        } if([self.dataSource respondsToSelector:@selector(swipableViewController:segmentButtonAt:)]) {
            for(int i=0; i<numControllers; i++) {
                UIButton *button = [self.dataSource swipableViewController:self segmentButtonAt:i];
                button.tag = [self tagByButtonIndex:i];
                [button removeTarget:self action:@selector(tapSegmentButton:) forControlEvents:UIControlEventTouchUpInside];  // if exists, get rid of it
                [button addTarget:self action:@selector(tapSegmentButton:) forControlEvents:UIControlEventTouchUpInside];
                baseFrame.size = button.frame.size;
                [segmentContainerScrollView addSubview:button];
                baseFrame.origin.x += button.frame.size.width + self.segmentButtonMarginWidth;
            }
        }
    }
    // end position of width of content should be affected by segmentButtonEdgeMarginWidth
    float contentWidth = baseFrame.origin.x - self.segmentButtonMarginWidth + self.segmentButtonEdgeMarginWidth;
    segmentContainerScrollView.contentSize = CGSizeMake(contentWidth, self.segmentButtonHeight);
    segmentContainerScrollView.scrollEnabled = YES;
    segmentContainerScrollView.scrollsToTop = NO;
    segmentContainerScrollView.showsHorizontalScrollIndicator = NO;
    segmentContainerScrollView.showsVerticalScrollIndicator = NO;
    segmentContainerScrollView.alwaysBounceVertical = NO;
    segmentContainerScrollView.minimumZoomScale = 1;
    segmentContainerScrollView.maximumZoomScale = 1;
    segmentContainerScrollView.clipsToBounds = YES;
    segmentContainerScrollView.backgroundColor = self.segmentContainerScrollViewBackgroundColor;

    [self.pageController.view addSubview:segmentContainerScrollView];
    self.pageController.view.clipsToBounds = NO;
    self.pageController.view.tag = RK_PAGE_CONTROLLER_VIEW_TAG;

    /////////////////
    // setup selector
    UIView *firstButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:0]];
    float selectionBarY = segmentContainerScrollView.frame.size.height - SELECTOR_HEIGHT - 1;
    selectionBar = [[UIView alloc] initWithFrame:CGRectMake(firstButton.frame.origin.x,selectionBarY,firstButton.frame.size.width,SELECTOR_HEIGHT)];
    selectionBar.backgroundColor = self.selectionBarColor;
    selectionBar.alpha = 0.8; //%%% sbalpha
    [segmentContainerScrollView addSubview:selectionBar];

    /////////////////
    // setup border
    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(-segmentContainerScrollView.frame.size.width, self.segmentButtonHeight-1, segmentContainerScrollView.contentSize.width + segmentContainerScrollView.frame.size.width * 2, 1)];
    border.backgroundColor = [UIColor colorWithWhite:0.66f alpha:1];
    [segmentContainerScrollView addSubview:border];
}

- (long)tagByButtonIndex:(long)buttonIndex {
    if(buttonIndex < 0)
        return TAG_BUTTON_INDEX + buttonIndex + [self.dataSource numberOfViewControllers:self];
    else
        return TAG_BUTTON_INDEX + buttonIndex;
}

- (long)buttonIndexByTag:(long)tag {
    return tag - TAG_BUTTON_INDEX;
}

- (void)setupConstraints {
    if(_pageController == self.visibleViewController) {
        segmentContainerScrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _pageController.view.translatesAutoresizingMaskIntoConstraints = NO;

        NSLayoutConstraint *c;
//        c = [NSLayoutConstraint constraintWithItem:segmentContainerScrollView
//                                         attribute:NSLayoutAttributeBottom
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:_pageController.view
//                                         attribute:NSLayoutAttributeTop
//                                        multiplier:1
//                                          constant:0];
//        [_pageController.view addConstraint:c];
//        c = [NSLayoutConstraint constraintWithItem:segmentContainerScrollView
//                                         attribute:NSLayoutAttributeLeft
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:_pageController.view
//                                         attribute:NSLayoutAttributeLeft
//                                        multiplier:1
//                                          constant:0];
//        [self.view addConstraint:c];
//        c = [NSLayoutConstraint constraintWithItem:segmentContainerScrollView
//                                         attribute:NSLayoutAttributeRight
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:_pageController.view
//                                         attribute:NSLayoutAttributeRight
//                                        multiplier:1
//                                          constant:0];
//        [self.view addConstraint:c];
//        c = [NSLayoutConstraint constraintWithItem:segmentContainerScrollView
//                                         attribute:NSLayoutAttributeHeight
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:nil
//                                         attribute:NSLayoutAttributeNotAnAttribute
//                                        multiplier:1
//                                          constant:self.segmentButtonHeight];
//        [self.view addConstraint:c];
        c = [NSLayoutConstraint constraintWithItem:_pageController.view
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.navigationBar
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1
                                          constant:self.segmentButtonHeight];
        [self.view addConstraint:c];
        c = [NSLayoutConstraint constraintWithItem:_pageController.view
                                         attribute:NSLayoutAttributeLeft
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeLeft
                                        multiplier:1
                                          constant:0];
        [self.view addConstraint:c];
        c = [NSLayoutConstraint constraintWithItem:_pageController.view
                                         attribute:NSLayoutAttributeRight
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeRight
                                        multiplier:1
                                          constant:0];
        [self.view addConstraint:c];
        c = [NSLayoutConstraint constraintWithItem:_pageController.view
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeBottom
                                        multiplier:1
                                          constant:0];
        [self.view addConstraint:c];
    }
}

//generally, this shouldn't be changed unless you know what you're changing
#pragma mark Setup

//%%% generic setup stuff for a pageview controller.  Sets up the scrolling style and delegate for the controller
- (void)setupPageViewController {
    _pageController.delegate = self;
    _pageController.dataSource = self;
//    UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:0];
//    [_pageController setViewControllers:@[vcToBeShown] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

//%%% this allows us to get information back from the scrollview, namely the coordinate information that we can link to the selection bar.
- (void)syncScrollView {
    for (UIView* view in _pageController.view.subviews) {
        if([view isKindOfClass:[UIScrollView class]] && view != self.segmentContainerScrollView) {
            self.pageScrollView = (UIScrollView *)view;
            self.pageScrollView.delegate = self;
        }
    }
}

//%%% methods called when you tap a button or scroll through the pages
// generally shouldn't touch this unless you know what you're doing or
// have a particular performance thing in mind

#pragma mark Movement
- (void)tapSegmentButtonIndex:(long)index animated:(BOOL)animated {
    for(UIView *v in self.segmentContainerScrollView.subviews) {
        if([self buttonIndexByTag:v.tag] == index) {
            UIButton *button = (UIButton *)v;
            [self tapSegmentButton:button animated:animated];
        }
    }
}

//%%% when you tap one of the buttons, it shows that page,
//but it also has to animate the other pages to make it feel like you're crossing a 2d expansion,
//so there's a loop that shows every view controller in the array up to the one you selected
//eg: if you're on page 1 and you click tab 3, then it shows you page 2 and then page 3
- (void)tapSegmentButton:(UIButton *)button {
    [self tapSegmentButton:button animated:self.isScrolledWhenTapSegment];
}

- (void)tapSegmentButton:(UIButton *)button animated:(BOOL)animated {
    NSInteger currentButtonTag = [self tagByButtonIndex:_currentPageIndex];
    __weak typeof(self) weakSelf = self;
    if (!isPageScrollingFlag) {
        //%%% check to see if you're going left -> right or right -> left
        if (button.tag > currentButtonTag) {
            if(animated) {
                doStopSegmentScrolling = YES;
                //%%% scroll through all the objects between the two points
                for (int tag = (int)currentButtonTag+1; tag<=button.tag; tag++) {
                    long buttonIndex = [self buttonIndexByTag:tag];
                    UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:buttonIndex];
                    [_pageController setViewControllers:@[vcToBeShown]
                                              direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished)
                    {
                        //%%% if the action finishes scrolling (i.e. the user doesn't stop it in the middle),
                        //then it updates the page that it's currently on
                        if (finished) {
                            [weakSelf setCurrentPageIndex:buttonIndex];
                            if(tag == button.tag) {
                                doStopSegmentScrolling = NO;
                            }
                        }
                    }];
                }
            } else {
                doStopSegmentScrolling = NO;
                long buttonIndex = [self buttonIndexByTag:button.tag];
                UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:buttonIndex];
                [_pageController setViewControllers:@[vcToBeShown]
                                          direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
                                              if (finished) {
                                                  [weakSelf setCurrentPageIndex:buttonIndex];
                                                  [weakSelf scrollViewDidScroll:weakSelf.pageScrollView];
                                              }
                                          }];
            }
        }
        //%%% this is the same thing but for going right -> left
        else if (button.tag < currentButtonTag) {
            if(animated) {
                doStopSegmentScrolling = YES;
                for (int tag = (int)currentButtonTag-1; tag >= button.tag; tag--) {
                    long buttonIndex = [self buttonIndexByTag:tag];
                    UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:buttonIndex];
                    [_pageController setViewControllers:@[vcToBeShown] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL complete){
                        if (complete) {
                            [weakSelf setCurrentPageIndex:buttonIndex];
                            if(tag == button.tag) {
                                doStopSegmentScrolling = NO;
                            }
                        }
                    }];
                }
            } else {
                doStopSegmentScrolling = NO;
                long buttonIndex = [self buttonIndexByTag:button.tag];
                UIViewController *vcToBeShown = [self.dataSource swipableViewController:self viewControllerAt:buttonIndex];
                [_pageController setViewControllers:@[vcToBeShown] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:^(BOOL complete){
                    if (complete) {
                        [weakSelf setCurrentPageIndex:buttonIndex];
                        [weakSelf scrollViewDidScroll:weakSelf.pageScrollView];
                    }
                }];
            }
        }
    }
}

//%%% makes sure the nav bar is always aware of what page you're on
//in reference to the array of view controllers you gave
- (void)setCurrentPageIndex:(long)newCurrentPageIndex {
    _currentPageIndex = newCurrentPageIndex;
    for(UIButton *btn in self.segmentContainerScrollView.subviews) {
        if([btn isMemberOfClass:[UIButton class]]) {
            long buttonIndex = [self buttonIndexByTag:btn.tag];
            btn.selected = buttonIndex == newCurrentPageIndex;
        }
    }
    if(self.doUpdateNavigationTitleWithSwipedViewController) {
        [self setNavigationBarTitle:[self.dataSource swipableViewController:self viewControllerAt:newCurrentPageIndex].title];
    }
}

//%%% method is called when any of the pages moves.
//It extracts the xcoordinate from the center point and instructs the selection bar to move accordingly
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat xFromCenter = self.view.frame.size.width - scrollView.contentOffset.x; //%%% positive for right swipe, negative for left
    CGFloat ratio = -1 * xFromCenter / self.view.frame.size.width;
    CGFloat absRatio = fabs(xFromCenter / self.view.frame.size.width);
    UIView *selectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:_currentPageIndex]];
    UIView *maybeSelectedButton = selectedButton;
    long vcCount = [self.dataSource numberOfViewControllers:self];
    NSAssert(0 <= _currentPageIndex && _currentPageIndex < vcCount, @"currentPageIndex over boundary: %ld", _currentPageIndex);
    CGRect buttonFrame = selectedButton.frame;
    CGRect selectionBarFrame = selectionBar.frame;
    selectionBarFrame.origin.x = buttonFrame.origin.x;
    if(ratio < 0 && _currentPageIndex == 0) {
        // over to left
        if(isSegmentScrolledOverBoundary) {
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:(vcCount-1)]];
            selectionBarFrame.origin.x = selectedButton.frame.origin.x + pow(absRatio,2) * (maybeSelectedButton.frame.origin.x);
        } else {
            selectionBarFrame.origin.x += absRatio * (-buttonFrame.size.width);
        }
    } else if(ratio > 0 && _currentPageIndex == vcCount-1) {
        // over to right
        if(isSegmentScrolledOverBoundary) {
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:0]];
            selectionBarFrame.origin.x = selectedButton.frame.origin.x - (pow(absRatio,2) * selectedButton.frame.origin.x);
        } else {
            selectionBarFrame.origin.x += absRatio * (buttonFrame.size.width);
        }
    } else {
        if(ratio > 0)
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:_currentPageIndex + 1]];
        if(ratio < 0)
            maybeSelectedButton = [self.segmentContainerScrollView viewWithTag:[self tagByButtonIndex:_currentPageIndex - 1]];
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
    CGPoint contentOffset = self.segmentContainerScrollView.contentOffset;
    CGRect scrollViewFrame = self.segmentContainerScrollView.frame;
    float leftX = selectionBarFrame.origin.x;
    float rightX = selectionBarFrame.origin.x + selectionBarFrame.size.width;
    if(self.shouldSelectedButtonCentered) {
        float centerXInContentView = self.selectionBar.frame.origin.x + (self.selectionBar.frame.size.width / 2);
        CGPoint contentOffset = self.segmentContainerScrollView.contentOffset;
        contentOffset.x = centerXInContentView - (self.segmentContainerScrollView.frame.size.width / 2);
        float maxContentOffsetX = self.segmentContainerScrollView.contentSize.width - self.segmentContainerScrollView.frame.size.width;
        if(contentOffset.x < 0)
            contentOffset.x = 0;
        else if(contentOffset.x > maxContentOffsetX)
            contentOffset.x = maxContentOffsetX;
        self.segmentContainerScrollView.contentOffset = contentOffset;
    } else {
        if(!doStopSegmentScrolling) {
            // scroll to left
            if(leftX < contentOffset.x) {
                if(leftX < 0)
                    contentOffset.x = 0;
                else
                    contentOffset.x = leftX;
                contentOffset.x -= self.segmentButtonMarginWidth;
                self.segmentContainerScrollView.contentOffset = contentOffset;
            }
            // scroll to right
            float segmentContainerWidth = self.segmentContainerScrollView.frame.origin.x + segmentContainerScrollView.contentSize.width;
            if(rightX > contentOffset.x + scrollViewFrame.size.width) {
                if(rightX > segmentContainerWidth) {
                    contentOffset.x = segmentContainerWidth - scrollViewFrame.size.width;
                }
                else {
                    contentOffset.x = selectionBarFrame.origin.x + selectionBarFrame.size.width - scrollViewFrame.size.width;
                }
                self.segmentContainerScrollView.contentOffset = contentOffset;
            }
        }
    }
}


#pragma mark - ETC
- (void)setNavigationBarTitle:(NSString *)title {
    _pageController.title = title;
}


//%%% the delegate functions for UIPageViewController.
//Pretty standard, but generally, don't touch this.
#pragma mark - UIPageViewController Delegate
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        UIViewController *shownVC = [pageViewController.viewControllers lastObject];
        [self setCurrentPageIndex:[self.dataSource swipableViewController:self indexOfViewController:shownVC]];
    }
}

#pragma mark - UIPageViewController Data Source
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


#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    isPageScrollingFlag = YES;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0) {
    long vcCount = [self.dataSource numberOfViewControllers:self];
    UIView *scrollTargetButton = nil;
    UIView *scrollSourceButton = nil;
    // to left at first page
    if(targetContentOffset->x == 0 && _currentPageIndex == 0) {
        scrollSourceButton = [segmentContainerScrollView viewWithTag:[self tagByButtonIndex:0]];
        scrollTargetButton = [segmentContainerScrollView viewWithTag:[self tagByButtonIndex:(vcCount-1)]];
    }
    // to right at last page
    if(targetContentOffset->x >= scrollView.frame.size.width*1.5 && _currentPageIndex == (vcCount-1)) {
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



@implementation UIView (RKSwipableViewController_FakePointInside)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method pointInside = class_getInstanceMethod([UIView class], @selector(pointInside:withEvent:));
        Method originalPointInside = class_getInstanceMethod([UIView class], @selector(odk_originalPointInside:withEvent:));
        Method fakePointInside = class_getInstanceMethod([UIView class], @selector(odk_fakePointInside:withEvent:));
        method_setImplementation(originalPointInside, method_getImplementation(pointInside));
        method_setImplementation(pointInside, method_getImplementation(fakePointInside));
    });
}

- (BOOL)odk_originalPointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [self odk_originalPointInside:point withEvent:event];
}

- (BOOL)odk_fakePointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if([self odk_originalPointInside:point withEvent:event])
        return YES;
    // if Page Controller view
    if(self.tag == RK_PAGE_CONTROLLER_VIEW_TAG) {
        for(UIView *v in self.subviews) {
            CGPoint converted = [v convertPoint:point fromView:self];
            if([v odk_originalPointInside:converted withEvent:event])
                return YES;
        }
    }
    return NO;
}

@end
