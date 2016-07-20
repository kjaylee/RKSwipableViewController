from Kenial: This class is forked from https://github.com/cwRichardKim/RKSwipeBetweenViewControllers. 
This has been updated in order to provide with dynamic page creation feature (ie. by using delegate), 
there's no compatibility anymore. I might send pull requests to original repo, but I thought original class 
might be more suitable static content, so decided to make it as another project. With a respect to the 
original author, I left prefix 'RK'. Thanks for your great efforts, Richard :)

I added some features like looping and scrollable fragment (above tab buttons) as well:

![demo](http://i.imgur.com/aUalMKK.gif)

Below descriptions 



RKSwipableViewController
===========================

UIPageViewController and custom UISegmentedControl synchronized and animated.  Similar to Spotify's "My Music" section.

__Please check the .h to see how to customize anything__

##Pod
You should not use the pod in most cases, as they don't allow for customizability.  I would recommend dragging the .h and .m files manually into your project
	
	pod 'RKSwipableViewController'
	

##Updates, Questions, and Requests
[twitter](https://twitter.com/cwRichardKim) <--- I am a very light twitterer, so I won't spam you

## Demo: 
(after five minutes of customization)

![demo](http://i.imgur.com/zlfWDa1.gif)

Any number of any view controllers should technically work, though it doesn't look great with more than 4

__Customizable!__

![Customizable!](http://i.imgur.com/dl422EL.gif)

(check the RKSwipableViewController.h for *actual* customizable features)

## how to use 
(check out the provided AppDelegate to see an example):

__Programmatically__ (preferred)

1. Import RKSwipableViewController.h
	
	```objc
	#import <RKSwipableViewController/RKSwipableViewController.h>
	```

2. Initialize a UIPageViewController
	
	```objc
	UIPageViewController *pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
	```
3. Initialize a RKSwipableViewController

  	```objc
	RKSwipableViewController *navigationController = [[RKSwipableViewController alloc]initWithRootViewController:pageController];
	```
4. Add all your ViewControllers (in order) to navigationController.viewControllerArray (try to keep it under 5)
  	
	```objc
	[navigationController.viewControllerArray addObjectsFromArray:@[viewController1, viewController2, viewController3]];
	```
5. Use the custom class (or call it as the first controller from app delegate: see below)
  	
	```objc
  	self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  	self.window.rootViewController = navigationController;
  	[self.window makeKeyAndVisible];
  	```
  
__StoryBoard__
(do not use pods for this one)

1. Drop the file into your project and import RKSwipableViewController.h
	
	```objc
	#import RKSwipableViewController.h
	```

2. Embed a UIPageViewController inside a UINavigationController.  Change the class of the to UINavigationController the custom class (RKSwipableViewController)
3. change the transition style of the pageviewcontroller to scroll (click on the UIPageViewController in storyboard -> attributes inspector -> transition style -> scroll)

4. go to the RKSwipableViewController.m file and use it as your own class now.  Add your view controllers to "viewControllerArray".  See below for various options.

	*Programmatically, outside RKSwipableViewController.m*
	(if this navigation bar isn't the first screen that comes up, or if you want to call it from the delegate)
	
	```objc
	[customNavController.viewControllerArray addObjectsFromArray:@[viewController1, viewController2, viewController3]];
	```
	
	*Programmatically, inside RKSwipableViewController.m*
	(most cases if your view controllers are programmatically created)
	
	```objc
	[viewControllerArray addObjectsFromArray:@[demo,demo2]];
	```
	*storyboard, inside RKSwipableViewController.m*
	(if your viewcontrollers are on the storyboard, but make sure to give them storyboard IDs)
	
	```objc
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	    UIViewController* theController = [storyboard instantiateViewControllerWithIdentifier:@"storyboardID"];
	
	    [viewControllerArray addObject:theController];
	```
	*storyboard, outside RKSwipableViewController.m*
	(if your viewcontrollers are on the storyboard, but make sure to give them storyboard IDs)
	
	```objc
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
	    UIViewController* theController = [storyboard instantiateViewControllerWithIdentifier:@"storyboardID"];
	
	    [theCustomViewController.viewControllerArray addObject:theController];
	```


Any problems/questions? shoot me a pm

### Areas for Improvement / Involvement
* Working with horizontal layout
* Working with more than 5 pages
* Handful of infrequent bugs
* Better performance when loading pages
* Changing layout away from UINavigationController to allow the bar to be at the bottom
* Bug: adding a MKMapView to a UIViewController in storyboard causes strange visual bug. Adding programmatically is fine
* Crash on load for UITabBarControllers (resolved): https://github.com/cwRichardKim/RKSwipableViewController/pull/15
