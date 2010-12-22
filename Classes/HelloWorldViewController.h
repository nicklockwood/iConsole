//
//  HelloWorldViewController.h
//  HelloWorld
//
//  Created by Nick Lockwood on 10/03/2010.
//  Copyright Charcoal Design 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iConsole.h"


@interface HelloWorldViewController : UIViewController <UITextFieldDelegate, iConsoleDelegate>
{	
	UILabel *label;
	UITextField *field;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UITextField *field;
@property (nonatomic, retain) IBOutlet UILabel *swipeLabel;

- (IBAction)sayHello:(id)sender;
- (IBAction)crash:(id)sender;

@end

