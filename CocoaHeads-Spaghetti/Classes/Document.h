//
//  Document.h
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import <AppCoreKit/AppCoreKit.h>

@class Timeline;

//User -----------------------------------------------------------------------

@interface User : CKObject
//Base
@property(nonatomic,copy) NSString* identifier;
@property(nonatomic,copy) NSString* name;
@property(nonatomic,copy) NSURL* avatarURL;

//Details
@property(nonatomic,assign) BOOL hasFetchedDetails;      //An example of Presentation Model specific property
                                                         //This property is not part of the business intelligence on the twitter side database
                                                         //But it helps us managing our flow
                                                         //     => So ... it's good for us. We can and we MUST do such things in our models
                                                         //        as their role is to help us representing the data !
@property(nonatomic,copy)   NSURL* backgroundImageURL;
@property(nonatomic,assign) NSInteger numberOfFollowers;
@property(nonatomic,assign) NSInteger numberOfFriends;
@property(nonatomic,copy)   NSString* city;
@property(nonatomic,copy)   NSString* details;
@property(nonatomic,retain) Timeline* userTimeline;
@end


//User Registry ---------------------------------------------------------------

//This class allow to ensure we have the same User instance when we get users in WebService payloads
//It references users per identifier

@interface UserRegistry : CKObject
@property(nonatomic,retain) NSMutableDictionary* registry; //User identifier to User instance weakref
@end


//Tweet -----------------------------------------------------------------------

@interface Tweet : CKObject
@property(nonatomic,copy)   NSString* identifier;
@property(nonatomic,copy)   NSString* text;
@property(nonatomic,retain) User* user;
@end


//Timeline --------------------------------------------------------------------

@interface Timeline : CKObject
@property(nonatomic,retain) CKArrayCollection* tweets;
@end