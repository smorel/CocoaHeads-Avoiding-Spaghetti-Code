//
//  Document.h
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import <AppCoreKit/AppCoreKit.h>

@interface User : CKObject
@property(nonatomic,copy) NSString* identifier;
@property(nonatomic,copy) NSString* name;
@property(nonatomic,copy) NSURL* avatarURL;

//User Details
@property(nonatomic,assign) BOOL hasFetchedDetails;
@property(nonatomic,copy) NSURL* backgroundImageURL;
@property(nonatomic,assign) NSInteger numberOfFollowers;
@property(nonatomic,assign) NSInteger numberOfFriends;
@property(nonatomic,copy) NSString* city;
@property(nonatomic,copy) NSString* details;
@end



@interface UserRegistry : CKObject
@property(nonatomic,retain) NSMutableDictionary* registry; //User identifier to User instance
@end



@interface Tweet : CKObject
@property(nonatomic,copy) NSString* identifier;
@property(nonatomic,copy) NSString* text;
@property(nonatomic,retain) User* user;
@end



@interface Timeline : CKObject
@property(nonatomic,retain) CKArrayCollection* tweets;
@end