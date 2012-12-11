//
//  AppDelegate.m
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import "AppDelegate.h"
#import "FlowManagerPhone.h"
#import "FlowManagerPad.h"
#import <AppCoreKit/AppCoreKit.h>


@implementation CKLicense(NoSpaghettiSample)

+ (NSString*)licenseKey{
    return @"eS4+1tnvTjV83NmLsYL/cWZUrAgZeFzs21qLnI98Az12+BBrEAJLnbyNC90GJRyfhn9Jqp8myUYg0bwyMi6mB6JPhz0Nc1P/BU+ijHvHP9lYGjOv2n3igoaBUk1oLOWAwppuBYPj38oWiHuTBO/8XidlK2+RJVuhCZ/gXQXi0ppwGr8u9ALpiIZxkoe+p9ubkKoJDZj0Q3TF7VTI+b56QGjTQ/QI2nWDPd/QgR970S66mfHAHSJtXtlOYc8i3rOeoUDsNYmImSxX+ds7DCROMoN2hpJfslgiKuR136yPBJ/Dtn4FCuMryhEP30EqnDZ1jOygdPwnzafEvEoG1iPfNg==";
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
    if([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        [[FlowManagerPhone sharedInstance] startInWindow:self.window];
    }else{
        [[FlowManagerPad sharedInstance] startInWindow:self.window];
    }
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end
