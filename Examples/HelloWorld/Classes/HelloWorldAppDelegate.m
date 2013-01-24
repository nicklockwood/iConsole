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

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    _window = [[iConsoleWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	_window.rootViewController = [[HelloWorldViewController alloc] init];
    [_window makeKeyAndVisible];
}

@end
