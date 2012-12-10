//
//  CellControllerFactory.m
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import "CellControllerFactory.h"
#import "ViewControllerFactory.h" //For intents


@implementation CellControllerFactory

+ (CKTableViewCellController*)cellControllerForTweet:(Tweet*)tweet
                                              intent:(void(^)(CKTableViewCellController* cellController, NSInteger intent, id object))intentBlock{
    CKTableViewCellController* cellController = [CKTableViewCellController cellController];
    
    //Explicitly do not retain cellController when using in blocks to avoid circular references
    __block CKTableViewCellController* bCellController = cellController;
    
    //Binds the model to the cell controller properties
    [cellController beginBindingsContextByRemovingPreviousBindings];
    [tweet bind:@"user.name" toObject:cellController withKeyPath:@"text"];
    [tweet bind:@"text" toObject:cellController withKeyPath:@"detailText"];
    
    CKImageLoader* imageLoader = [[CKImageLoader alloc]init];
    [tweet bind:@"user.avatarURL" executeBlockImmediatly:YES withBlock:^(id value) {
        NSURL* imageUrl = [[tweet user]avatarURL];
        
        //fetch the image and sets the cellController image
        if(imageUrl){
            imageLoader.completionBlock = ^(CKImageLoader* imageLoader, UIImage* image, BOOL loadedFromCache){
                bCellController.image = [image imageThatFits:CGSizeMake(40,40) crop:NO];
            };
            [imageLoader loadImageWithContentOfURL:imageUrl];
        }
        
        //If the image is not ready yet (not loaded from cache) sets a default image
        if(!bCellController.image){
            bCellController.image = [[UIImage imageNamed:@"default_avatar"]imageThatFits:CGSizeMake(40,40) crop:NO];
        }
    }];
    [cellController endBindingsContext];
    
    
    //Manages selection
    
    cellController.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cellController.flags = CKTableViewCellFlagSelectable;
    [cellController setSelectionBlock:^(CKTableViewCellController *controller) {
        if(intentBlock){
            intentBlock(controller,TweetSelectionIntent,tweet);
        }
    }];
    
    
    //Manages UITableViewCell Extra views to add interaction on avatar image
    
    //Equivalent of viewDidLoad on a viewController
    //The Init block is called when a UITableViewCell needs to be created as we have not enough views to re-use
    
    [cellController setInitBlock:^(CKTableViewCellController *controller, UITableViewCell *cell) {
        //Here we add a transparent button on top of the UITableViewCell imageView to catch user touch on it
        UIButton* avatarImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        avatarImageButton.frame = cell.imageView.bounds;
        avatarImageButton.autoresizingMask = UIViewAutoresizingFlexibleSize;
        avatarImageButton.name = @"avatarImageButton";
        [cell.imageView addSubview:avatarImageButton];
        
        //Enables interactions here to forward the event to the child button
        cell.imageView.userInteractionEnabled = YES;
    }];
    
    
    //Equivalent of viewWillAppear on a viewController
    //The Setup block is called after a UITableViewCell has been created and when reusing a UITableViewCell
    
    [cellController setSetupBlock:^(CKTableViewCellController *controller, UITableViewCell *cell) {
        UIButton* avatarImageButton = [cell.imageView viewWithKeyPath:@"avatarImageButton"];
        [cell beginBindingsContextByRemovingPreviousBindings];
        [avatarImageButton bindEvent:UIControlEventTouchUpInside withBlock:^{
            if(intentBlock){
                intentBlock(controller,TweetAvatarTouchIntent,tweet);
            }
        }];
        [cell endBindingsContext];
    }];
    
    //The CKTableViewCellStyleSubtitle2 but it manages the cell size dynamically to adjust to its content
    //The Layout block is called each time a UITableViewCell changes its bounds
    
    cellController.cellStyle = CKTableViewCellStyleSubtitle2;
    [cellController setLayoutBlock:^(CKTableViewCellController *controller, UITableViewCell *cell) {
        //Performs the default layout
        [controller performLayout];
        
        //Align the imageView top left
        cell.imageView.frame = CGRectMake(controller.contentInsets.left,controller.contentInsets.top,40,40);
    }];
    
    return cellController;
}

@end
