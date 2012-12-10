//
//  WebService.h
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import <AppCoreKit/AppCoreKit.h>
#import "Document.h"


@interface WebService : NSObject

+ (CKFeedSource*) feedSourceForTimeline;
+ (CKFeedSource*) feedSourceForUserTimeline:(NSString*)userIdentifier;

+ (void)performRequestForUserDetails:(User*)user completion:(void(^)(User* user, NSError* error))completion;

@end