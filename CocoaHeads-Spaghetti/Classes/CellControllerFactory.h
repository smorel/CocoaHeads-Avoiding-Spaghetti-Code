//
//  CellControllerFactory.h
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import <AppCoreKit/AppCoreKit.h>
#import "Document.h"


@interface CellControllerFactory : NSObject

+ (CKTableViewCellController*)cellControllerForTweet:(Tweet*)tweet intent:(void(^)(CKTableViewCellController* cellController, NSInteger intent, id object))intent;

@end