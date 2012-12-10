//
//  AppDelegate.m
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import "AppDelegate.h"
#import "FlowManager.h"
#import <AppCoreKit/AppCoreKit.h>


@implementation CKLicense(NoSpaghettiSample)

+ (NSString*)licenseKey{
    return @"YourLicenseKey";
}

@end


@implementation AppDelegate

- (id)init{
   self = [super init];
    
    //Initializing AppCoreKit Technologies
   [[CKStyleManager defaultManager]loadContentOfFileNamed:@"Stylesheet"];
   [CKMappingContext loadContentOfFileNamed:@"Api"];
    
#ifdef DEBUG
    [CKConfiguration initWithContentOfFileNames:@"AppCoreKit" type:CKConfigurationTypeDebug];
#else
    [CKConfiguration initWithContentOfFileNames:@"AppCoreKit" type:CKConfigurationTypeRelease];
#endif
    
#ifdef __has_feature(objc_arc)
    [[CKConfiguration sharedInstance]setUsingARC:YES];
#endif

   return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [UIWindow  viewWithFrame:[[UIScreen mainScreen] bounds]];
    //Starting the flowManager
    [[FlowManager sharedInstance] startInWindow:self.window];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
