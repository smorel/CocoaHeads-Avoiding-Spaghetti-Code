//
//  Sample.m
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import "FlowManager.h"
#import "WebService.h"
#import "ViewControllerFactory.h"



@implementation FlowManager

- (void)startInWindow:(UIWindow*)window{
    __block FlowManager* bself = self;
    
    //Setup the document and its remote data source
    Timeline* sharedTimeline = [Timeline sharedInstance];
    sharedTimeline.tweets.feedSource = [WebService feedSourceForHomeTimeline];
    
    //Create the view controller by passing the data it should represents and managing its intent
    CKViewController* timelineController = [ViewControllerFactory viewControllerForTimeline:sharedTimeline
                                                                                     intent:^(CKViewController* viewController, NSInteger intent, id object) {
        Tweet* tweet = (Tweet*)object;
        switch(intent){
            case TweetAvatarTouchIntent:{
                [bself presentsViewControllerForUserDetails:tweet.user fromViewController:viewController];
                break;
            }
            case TweetSelectionIntent:{
                [bself presentsViewControllerForTweetDetails:tweet fromViewController:viewController];
                break;
            }
        }
    }];
    
    //Customizing the ViewController navigation item (This is specific for the iPhone Flow)
    __block CKViewController* bTimelineController = timelineController;
    timelineController.title = _(@"Spaghetti - Home");
    timelineController.rightButton = [[UIBarButtonItem alloc]initWithTitle:_(@"Write") style:UIBarButtonItemStyleBordered block:^{
        [bself presentsViewControllerForNewTweetFromViewController:bTimelineController];
    }];
    
    //Sets the window's root view controller
    UINavigationController* mainNavigationController = [UINavigationController navigationControllerWithRootViewController:timelineController];
    window.rootViewController = mainNavigationController;
}



- (void)presentsViewControllerForUserDetails:(User*)user fromViewController:(CKViewController*)viewController{
    __block FlowManager* bself = self;
    
    //We wrap 2 controllers that can be created at different time in a container controller.
    //A pending controller displaying a spinner and the user detail controller that will get created when the data has been fetched.
    //This is particularily usefull for defining the pending behaviour and to swicth with animations.
    
    CKViewController* pendingViewController = [ViewControllerFactory viewControllerForPendingOperation];
    pendingViewController.title = user.name;
    
    CKContainerViewController* container = [CKContainerViewController controller];
    [container setViewControllers:[NSArray arrayWithObject:pendingViewController]];
    
    
    //As this code will get called several times Asynchronously or synchronously, we centralize it in a block that gets the job done!
    //This could have been a method if you prefer ... Defining a block limits the usage of this particular behaviour
    //To this presentsViewControllerForUserDetails method.
    
    void(^presentationBlock)(CKContainerViewController* container, BOOL animated) = ^(CKContainerViewController* container, BOOL animated){
        CKViewController* controllerForUserDetails = [ViewControllerFactory viewControllerForUserDetails:user intent:^(CKViewController *viewController, NSInteger intent, id object) {
            switch(intent){
                case UserTweetAvatarTouchIntent:{
                    //Does nothing here as we are currently watching the user detail for this tweet
                    break;
                }
                case UserTweetSelectionIntent:{
                    [bself presentsViewControllerForTweetDetails:((Tweet*)object) fromViewController:viewController];
                    break;
                }
                case UserSendMessageIntent:{
                    [bself presentsViewControllerForMessageToUser:((User*)object) fromViewController:viewController];
                    break;
                }
            }
        }];
        controllerForUserDetails.title = user.name;
        
        NSMutableArray* controllers = [NSMutableArray arrayWithArray:[container viewControllers]];
        [controllers addObject:controllerForUserDetails];
        [container setViewControllers:controllers];
        
        [container presentViewControllerAtIndex:1 withTransition:animated ? CKTransitionCrossDissolve : CKTransitionNone];
    };
    
    if(!user.hasFetchedDetails){
        [WebService performRequestForUserDetails:user completion:^(User *user, NSError *error) {
            if(!error){
                presentationBlock(container,YES);
            }
        }];
    }else{
        presentationBlock(container,NO);
    }
    
    [viewController.navigationController pushViewController:container animated:YES];
}

- (void)presentsViewControllerForTweetDetails:(Tweet*)tweet fromViewController:(CKViewController*)viewController{
    CKAlertView* alert = [[CKAlertView alloc]initWithTitle:_(@"Tweet Details")
                                                   message:_(@"The Flow Manager can create a detail view controller for this tweet and push the detail in the navigation ...")];
    [alert addButtonWithTitle:_(@"OK") action:nil];
    [alert show];
}

- (void)presentsViewControllerForNewTweetFromViewController:(CKViewController*)viewController{
    CKAlertView* alert = [[CKAlertView alloc]initWithTitle:_(@"New Tweet")
                                                   message:_(@"The Flow Manager can create a view controller to compose a tweet with send button intent and present it as modal, adding a cancel button to the left. Sends the created tweet through the API for send intent")];
    [alert addButtonWithTitle:_(@"OK") action:nil];
    [alert show];
}

- (void)presentsViewControllerForMessageToUser:(User*)user fromViewController:(CKViewController*)viewController{
    CKAlertView* alert = [[CKAlertView alloc]initWithTitle:_(@"Send Message")
                                                   message:_(@"The Flow Manager can create a view controller to compose a message with send button intent and present it as modal, adding a cancel button to the left. Sends the created message to the specified user through the API for send intent")];
    [alert addButtonWithTitle:_(@"OK") action:nil];
    [alert show];
}

@end

