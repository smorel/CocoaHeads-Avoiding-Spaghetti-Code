//
//  WebService.m
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import "WebService.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@implementation WebService


+ (void)authentificationError{
    CKAlertView* alert = [[CKAlertView alloc]initWithTitle:_(@"Twitter") message:_(@"Authentification Failed")];
    [alert addButtonWithTitle:_(@"OK") action:nil];
    [alert show];
}

+ (void)requestTwitterAccountWithCompletionBlock:(void(^)(ACAccount* account))completionBlock{
    //  First, we need to obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    //  Request permission from the user to access the available Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType
                     withCompletionHandler:^(BOOL granted, NSError *error) {
        if (!granted) {
            // The user rejected your request
            NSLog(@"User rejected access to the account.");
            completionBlock(nil);
        }
        else {
            // Grab the available accounts
            NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
                             
            if ([twitterAccounts count] > 0) {
                // Use the first account for simplicity
                ACAccount *account = [twitterAccounts objectAtIndex:0];
                completionBlock(account);
            }else{
                completionBlock(nil);
            }
        }
    }];
}


+ (void)performBlockWithObjects:(NSArray*)objects{
    void(^block)(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error ) = [objects objectAtIndex:0];
    id responseDataObject = ([objects count] >= 1) ? [objects objectAtIndex:1] : nil;
    id urlResponseObject = ([objects count] >= 2) ? [objects objectAtIndex:2] : nil;
    id errorObject = ([objects count] >= 3) ? [objects objectAtIndex:3] : nil;
    block([responseDataObject isKindOfClass:[NSNull class]] ? nil : responseDataObject,
          [urlResponseObject isKindOfClass:[NSNull class]] ? nil : urlResponseObject,
          [errorObject isKindOfClass:[NSNull class]] ? nil : errorObject);
}

+ (void)asyncTwitterRequestWithURL:(NSURL*)url
                            params:(NSDictionary*)params
                        completion:(void(^)(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error ))completion{
    
    //Requests the first twitter account from the device
    [self requestTwitterAccountWithCompletionBlock:^(ACAccount* account){
        if(!account){
            [self performSelector:@selector(authentificationError) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
        }else{
            //Performs twitter request for the specified URL and parameters.
            TWRequest *request = [[TWRequest alloc] initWithURL:url
                                                     parameters:params
                                                  requestMethod:TWRequestMethodGET];
            request.account = account;
            
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
                //Dispatch Completion on Main Thread
                NSArray* objects = [NSArray arrayWithObjects:
                                    [completion copy],
                                    responseData? responseData : [NSNull null],
                                    urlResponse ? urlResponse : [NSNull null],
                                    error ? error : [NSNull null],
                                    nil];
                [self performSelectorOnMainThread:@selector(performBlockWithObjects:) withObject:objects waitUntilDone:YES];
            }];
        }
    }];
}

+ (CKFeedSource*)feedSourceForTimelineWithURl:(NSURL*)url
                                       params:(NSDictionary*)params{
    
    CKFeedSource* feedSource = [CKFeedSource feedSource];
    feedSource.fetchBlock = ^(CKFeedSource* feedSource, NSRange range){
        CKCollection* associatedCollection = (CKCollection*)[feedSource delegate];
        NSString* lastId = (range.location > 0) ? [[associatedCollection objectAtIndex:range.location-1]identifier] : nil;
        
        NSMutableDictionary* dico = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     //As max_id returns the previous one in the payload we ask for 1 more
                                     [NSString stringWithFormat:@"%d",range.length + (lastId ? 1 : 0)],@"count",
                                     lastId,@"max_id",
                                     nil];
        [dico addEntriesFromDictionary:params];
        
        //Performs the request asynchronously
        [self asyncTwitterRequestWithURL:url params:dico completion:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            if ([urlResponse statusCode] == 200){
                //Converts JSON Raw Data To Array
                NSError *error;
                NSArray *array = [NSObject objectFromJSONData:responseData error:&error];
                
                //Maps the results into a collection of Tweet Objects
                CKMappingContext* context = [CKMappingContext contextWithIdentifier:@"$Tweet"];
                NSArray* tweets = [context objectsFromValue:array error:&error];
                
                //Dispatch Completion
                if([tweets count] > 1){
                    //As max_id returns the previous one in the payload weremove the ist item from the returned list
                    [feedSource addItems:[NSArray arrayWithArray:[tweets objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [tweets count] - 1)]]]];
                }else{
                    [feedSource cancelFetch];
                }
            }
            else{
                [feedSource cancelFetch];
                NSLog(@"Twitter error, HTTP response: %i", [urlResponse statusCode]);
            }

        }];
    };
    return feedSource;
}

+ (CKFeedSource*)feedSourceForHomeTimeline{
    return [self feedSourceForTimelineWithURl:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"]
                                       params:nil];
}

+ (CKFeedSource*) feedSourceForUserTimeline:(NSString*)userIdentifier{
    return [self feedSourceForTimelineWithURl:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/user_timeline.json"]
                                       params:[NSDictionary dictionaryWithObjectsAndKeys:userIdentifier,@"user_id", nil]];
}

+ (void)performRequestForUserDetails:(User*)user
                          completion:(void(^)(User* user, NSError* error))completionBlock{
    
    //Performs the request asynchronously
    [self asyncTwitterRequestWithURL:[NSURL URLWithString: @"http://api.twitter.com/1.1/users/show.json"]
                              params:[NSDictionary dictionaryWithObjectsAndKeys:user.identifier,@"user_id",nil]
                          completion:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                              
        if ([urlResponse statusCode] == 200){
            //Converts JSON Raw Data To Dictionary
            NSError *error;
            NSDictionary *dict = [NSObject objectFromJSONData:responseData error:&error];
            
            //Maps the results into our user object
            CKMappingContext* context = [CKMappingContext contextWithIdentifier:@"$UserDetails"];
            [context mapValue:dict toObject:user error:&error];
            
            //Dispatch completion
            if(completionBlock){
                completionBlock(user,NULL);
            }
        }
        else{
            NSLog(@"Twitter error, HTTP response: %i", [urlResponse statusCode]);
            if(completionBlock){
                completionBlock(user,error);
            }
        }
    }];
}

//Special transformer registering user in a shared register in order to get one unique instance per user in memory
+ (User*)userFromValue:(NSDictionary*)dictionary error:(NSError**)error{
    NSString* identifier = [dictionary objectForKey:@"id_str"];
    
    CKWeakRef* existingUserWeakRef = [[[UserRegistry sharedInstance]registry]objectForKey:identifier];
    if(existingUserWeakRef)
        return existingUserWeakRef.object;
    
    User* newUser = [User object];
    CKMappingContext* context = [CKMappingContext contextWithIdentifier:@"$UserBase"];
    [context mapValue:dictionary toObject:newUser error:error];
    
    //A weakref do not retain it's referencing object
    //That's what we want here !
    //By this way we delegate the life duration of User objects to the document's Tweets
    //If no more tweets in memory reference this user, it will get deleted and removed from the UserRegistry
    //Thanks to the following block mechanism.
    
    CKWeakRef* newUserWeakRef = [CKWeakRef weakRefWithObject:newUser block:^(CKWeakRef *weakRef) {
        [[[UserRegistry sharedInstance]registry]removeObjectForKey:[weakRef.object identifier]];
    }];
    [[[UserRegistry sharedInstance]registry] setObject:newUserWeakRef forKey:identifier];
    
    return newUser;
}

@end