//
//  ViewControllerFactory.m
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//


#import "ViewControllerFactory.h"
#import "CellControllerFactory.h"
#import "WebService.h"


//View Controllers   ----------------------------------------------------------------------

@implementation ViewControllerFactory

//As this section is reused in the main timeline controller and in the user detail controller,
//we choosed to setup it in a separate method
+ (CKFormBindedCollectionSection*)sectionForTimeline:(Timeline*)timeline
                                              intent:(void(^)(CKViewController* viewController, NSInteger intent, id object))intentBlock{
    
    //Setup a factory allowing to dynamically create cell controllers for specific objects inserted in the collection asynchronously
    CKCollectionCellControllerFactory* cellControllerFactory = [CKCollectionCellControllerFactory factory];
    
    [cellControllerFactory addItemForObjectOfClass:[Tweet class] withControllerCreationBlock:^CKCollectionCellController *(id object, NSIndexPath *indexPath) {
        CKTableViewCellController* cellController = [CellControllerFactory cellControllerForTweet:object
                                                                                           intent:^(CKTableViewCellController *cellController, NSInteger intent, Tweet *tweet) {
            //Forwards the intent to the mediator
            if(intentBlock){
                intentBlock(cellController.containerController,intent,tweet);
            }
        }];
        return cellController;
    }];
    
    //Create a form section binded on the collection with a cell controller factory
    CKFormBindedCollectionSection* timelineSection = [CKFormBindedCollectionSection sectionWithCollection:timeline.tweets factory:cellControllerFactory appendSpinnerAsFooterCell:YES];
    return timelineSection;
}


+ (CKViewController*)viewControllerForTimeline:(Timeline*)timeline
                                        intent:(void(^)(CKViewController* viewController, NSInteger intent, id object))intentBlock{
    //Creates a form with the timeline section
    CKFormTableViewController* form = [CKFormTableViewController controller];
    [form addSections:[NSArray arrayWithObject:[self sectionForTimeline:timeline intent:intentBlock]]];
    return form;
}

+ (CKViewController*)viewControllerForUserDetails:(User*)user
                                           intent:(void(^)(CKViewController* viewController, NSInteger intent, id object))intentBlock{
    //we know here that the user has been fetched completly in the flow manager
    //we dont need to bind on the values
    
    //User Detail section
    CKTableViewCellController* detailCellController = [CKTableViewCellController cellControllerWithTitle:nil
                                                                                                subtitle:([user.details length] > 0) ? user.details : _(@"No Details")
                                                                                            defaultImage:[UIImage imageNamed:@"default_avatar"]
                                                                                                imageURL:user.avatarURL
                                                                                               imageSize:CGSizeMake(40,40)
                                                                                                  action:nil];
    detailCellController.cellStyle = CKTableViewCellStyleSubtitle2;
    
    CKTableViewCellController* cityCellController      = [CKTableViewCellController cellControllerWithObject:user keyPath:@"city" readOnly:YES];
    cityCellController.cellStyle = CKTableViewCellStyleValue1;
    
    CKTableViewCellController* friendsCellController   = [CKTableViewCellController cellControllerWithObject:user keyPath:@"numberOfFriends" readOnly:YES];
    friendsCellController.cellStyle = CKTableViewCellStyleValue1;
    
    CKTableViewCellController* followersCellController = [CKTableViewCellController cellControllerWithObject:user keyPath:@"numberOfFollowers" readOnly:YES];
    followersCellController.cellStyle = CKTableViewCellStyleValue1;
    
    CKTableViewCellController* sendMessageCellController = [CKTableViewCellController cellControllerWithTitle:_(@"Send Message") action:^(CKTableViewCellController *controller) {
        if(intentBlock){
            intentBlock(controller.containerController,UserSendMessageIntent,user);
        }
    }];
    
    CKFormSection* detailsSection = [CKFormSection sectionWithCellControllers:[NSArray arrayWithObjects:detailCellController,cityCellController,friendsCellController,followersCellController,sendMessageCellController,nil]];
    
    //User tweets section
    Timeline* userTimeline = [Timeline object];
    userTimeline.tweets.feedSource = [WebService feedSourceForUserTimeline:user.identifier];
    CKFormBindedCollectionSection* userTweetsSection = [self sectionForTimeline:userTimeline intent:intentBlock];
    userTweetsSection.headerTitle = _(@"User Tweets");
    
    //Creates a form with the details and user timeline sections
    CKFormTableViewController* form = [CKFormTableViewController controller];
    [form addSections:[NSArray arrayWithObjects:detailsSection,userTweetsSection,nil]];
    
    //Customize background using the fetched user background image url
    form.viewDidLoadBlock = ^(CKViewController* controller){
        CKImageView* backgroundView = [[CKImageView alloc]initWithFrame:controller.view.bounds];
        backgroundView.imageURL = user.backgroundImageURL;
        backgroundView.imageViewContentMode = UIViewContentModeScaleAspectFill;
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleSize;
        [controller.view insertSubview:backgroundView atIndex:0];
    };
    
    return form;
}


+ (CKViewController*)viewControllerForPendingOperation{
    CKViewController* controller = [CKViewController controllerWithName:@"PendingOperation"];
    controller.viewDidLoadBlock = ^(CKViewController* controller){
        UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.center = CGPointMake(controller.view.width/2,controller.view.height/2);
        spinner.autoresizingMask = UIViewAutoresizingFlexibleAllMargins;
        spinner.name = @"Spinner";
        [controller.view addSubview:spinner];
    };
    
    controller.viewWillAppearBlock = ^(CKViewController* controller, BOOL animated){
        UIActivityIndicatorView* spinner = [controller.view viewWithKeyPath:@"Spinner"];
        [spinner startAnimating];
    };
    
    controller.viewWillDisappearBlock = ^(CKViewController* controller, BOOL animated){
        UIActivityIndicatorView* spinner = [controller.view viewWithKeyPath:@"Spinner"];
        [spinner stopAnimating];
    };
    
    return controller;
}

@end
