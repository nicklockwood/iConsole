//
//  HelloWorldAppDelegate.m
//  HelloWorld
//
//  Created by Nick Lockwood on 10/03/2010.
//  Copyright Charcoal Design 2010. All rights reserved.
//

#import "HelloWorldAppDelegate.h"
#import "HelloWorldViewController.h"

@implementation HelloWorldAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{        
	[window addSubview:viewController.view];
    [window makeKeyAndVisible];
}

- (void)dealloc
{
    [viewController release];
    [window release];
    [super dealloc];
}

@end
