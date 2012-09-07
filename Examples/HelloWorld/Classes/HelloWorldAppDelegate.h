//
//  HelloWorldAppDelegate.h
//  HelloWorld
//
//  Created by Nick Lockwood on 10/03/2010.
//  Copyright Charcoal Design 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HelloWorldViewController;

@interface HelloWorldAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    HelloWorldViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet HelloWorldViewController *viewController;

@end

