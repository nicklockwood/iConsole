//
//  HelloWorldViewController.m
//  HelloWorld
//
//  Created by Nick Lockwood on 10/03/2010.
//  Copyright Charcoal Design 2010. All rights reserved.
//

#import "HelloWorldViewController.h"
#import "iConsole.h"
#import "iConsoleManager.h"


@implementation HelloWorldViewController

- (IBAction)sayHello:(id)sender
{	
	NSString *text = _field.text;
	if ([text isEqualToString:@""])
	{
		text = @"World";
	}
	
	_label.text = [NSString stringWithFormat:@"Hello %@", text];
	[iConsole info:@"Said '%@'", _label.text];
}

- (IBAction)crash:(id)sender
{
	[[NSException exceptionWithName:@"HelloWorldException" reason:@"Demonstrating crash logging" userInfo:nil] raise];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [iConsole sharedConsole].delegate = self;

    
	int touches = (TARGET_IPHONE_SIMULATOR ? [iConsole sharedConsole].simulatorTouchesToShow: [iConsole sharedConsole].deviceTouchesToShow);
	if (touches > 0 && touches < 11)
	{
		self.swipeLabel.text = [NSString stringWithFormat:
								@"\nSwipe up with %i finger%@ to show the console",
								touches, (touches != 1)? @"s": @""];
	}
	else if (TARGET_IPHONE_SIMULATOR ? [iConsole sharedConsole].simulatorShakeToShow: [iConsole sharedConsole].deviceShakeToShow)
	{
		self.swipeLabel.text = @"\nShake device to show the console";
	}
							
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{	
	[textField resignFirstResponder];
	[self sayHello:self];
	return YES;
}

//- (void)handleConsoleCommand:(NSString *)command
//{
//	if ([command isEqualToString:@"version"])
//	{
//		[iConsole info:@"%@ version %@",
//         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
//		 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
//	}
//	else 
//	{
//		[iConsole error:@"unrecognised command, try 'version' instead"];
//	}
//}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
	self.label = nil;
	self.field = nil;
	self.swipeLabel = nil;
}

@end
