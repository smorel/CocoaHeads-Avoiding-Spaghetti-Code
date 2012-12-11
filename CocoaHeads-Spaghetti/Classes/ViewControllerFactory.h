//
//  ViewControllerFactory.h
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import <AppCoreKit/AppCoreKit.h>
#import "Document.h"

@interface ViewControllerFactory : NSObject

//Timeline
typedef enum TweetIntent{ TweetAvatarTouchIntent, TweetSelectionIntent } TweetIntent;

+ (CKViewController*)viewControllerForTimeline:(Timeline*)timeline
                                        intent:(void(^)(CKViewController* viewController, NSInteger intent, id object))intent;


//User Details
typedef enum UserIntent{ UserTweetAvatarTouchIntent = TweetAvatarTouchIntent, UserTweetSelectionIntent = TweetSelectionIntent, UserSendMessageIntent } UserIntent;

+ (CKViewController*)viewControllerForUserDetails:(User*)user
                                           intent:(void(^)(CKViewController* viewController, NSInteger intent, id object))intent;

//Pending Operations
+ (CKViewController*)viewControllerForPendingOperation;

@end
