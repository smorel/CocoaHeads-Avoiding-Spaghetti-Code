//
//  Document.m
//  CocoaHeads-Spaghetti
//
//  Created by Sebastien Morel on 12-12-10.
//  Copyright (c) 2012 Sebastien Morel. All rights reserved.
//

#import "Document.h"

@implementation User

- (void)postInit{
    [super postInit];
    self.userTimeline = [Timeline object];
}

@end

@implementation Tweet
@end

@implementation Timeline
@end


@implementation UserRegistry

- (void)postInit{
    [super postInit];
    self.registry = [NSMutableDictionary dictionary];
}

@end
