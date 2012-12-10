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

//TWRequest are not multi-threaded
//We could have used GCD to get data asynchronously in background


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
                             NSArray *twitterAccounts =
                             [store accountsWithAccountType:twitterAccountType];
                             
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


+ (CKFeedSource*)feedSourceForTimelineWithURl:(NSURL*)url params:(NSDictionary*)params{
    CKFeedSource* feedSource = [CKFeedSource feedSource];
    
    feedSource.fetchBlock = ^(CKFeedSource* feedSource, NSRange range){
        CKCollection* associatedCollection = (CKCollection*)[feedSource delegate];
        NSString* lastId = (range.location > 0) ? [[associatedCollection objectAtIndex:range.location-1]identifier] : nil;
        
        [self requestTwitterAccountWithCompletionBlock:^(ACAccount* account){
            if(!account){
                [self performSelector:@selector(authentificationError) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
            }else{
                NSMutableDictionary* dico = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             //As max_id returns the previous one in the payload we ask for 1 more
                                             [NSString stringWithFormat:@"%d",range.length + (lastId ? 1 : 0)],@"count",
                                             lastId,@"max_id",
                                             nil];
                [dico addEntriesFromDictionary:params];
                
                TWRequest *request = [[TWRequest alloc] initWithURL:url
                                                         parameters:dico
                                                      requestMethod:TWRequestMethodGET];
                request.account = account;
                
                // Notice this is a block, it is the handler to process the response
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
                    if ([urlResponse statusCode] == 200){
                        // The response from Twitter is in JSON format
                        // Move the response into a dictionary and print
                        NSError *error;
                        NSArray *dict = [NSObject objectFromJSONData:responseData error:&error];
                        CKMappingContext* context = [CKMappingContext contextWithIdentifier:@"$Tweet"];
                        NSArray* tweets = [context objectsFromValue:dict error:&error];
                        
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
            }
        }];
    };
    return feedSource;
}

+ (CKFeedSource*)feedSourceForTimeline{
    return [self feedSourceForTimelineWithURl:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"] params:nil];
}

+ (CKFeedSource*) feedSourceForUserTimeline:(NSString*)userIdentifier{
    return [self feedSourceForTimelineWithURl:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/user_timeline.json"] params:[NSDictionary dictionaryWithObjectsAndKeys:userIdentifier,@"user_id", nil]];
}

+ (void)performRequestForUserDetails:(User*)user completion:(void(^)(User* user, NSError* error))completionBlock{
    [self requestTwitterAccountWithCompletionBlock:^(ACAccount* account){
        if(!account){
            [self performSelector:@selector(authentificationError) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
        }else{
            TWRequest *request = [[TWRequest alloc] initWithURL:[NSURL URLWithString:
                                                                 @"http://api.twitter.com/1.1/users/show.json"]
                                                     parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                 user.identifier,@"user_id",
                                                                 nil]
                                                  requestMethod:TWRequestMethodGET];
            request.account = account;
            
            // Notice this is a block, it is the handler to process the response
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
                if ([urlResponse statusCode] == 200){
                    // The response from Twitter is in JSON format
                    // Move the response into a dictionary and print
                    NSError *error;
                    NSArray *dict = [NSObject objectFromJSONData:responseData error:&error];
                    CKMappingContext* context = [CKMappingContext contextWithIdentifier:@"$UserDetails"];
                    [context mapValue:dict toObject:user error:&error];
                    
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
    }];
}

//Special transformer registering user in a shared register in order to get one unique instance per user in memory
+ (User*)userFromValue:(NSDictionary*)dictionary error:(NSError**)error{
    NSString* identifier = [dictionary objectForKey:@"id_str"];
    User* existingUser = [[[UserRegistry sharedInstance]registry]objectForKey:identifier];
    if(existingUser)
        return existingUser;
    
    User* newUser = [User object];
    CKMappingContext* context = [CKMappingContext contextWithIdentifier:@"$UserBase"];
    [context mapValue:dictionary toObject:newUser error:error];
    [[[UserRegistry sharedInstance]registry] setObject:newUser forKey:identifier];
    return newUser;
}

@end