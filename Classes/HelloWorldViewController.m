//
//  HelloWorldViewController.m
//  HelloWorld
//
//  Created by Nick Lockwood on 10/03/2010.
//  Copyright Charcoal Design 2010. All rights reserved.
//

#import "HelloWorldViewController.h"
#import "iConsole.h"


@implementation HelloWorldViewController

@synthesize label, field;

- (IBAction)sayHello:(id)sender
{	
	NSString *text = field.text;
	if ([text isEqualToString:@""])
	{
		text = @"World";
	}
	
	label.text = [NSString stringWithFormat:@"Hello %@", text];
	[iConsole info:@"Said '%@'", label.text];
}

- (void)viewDidLoad
{
    [iConsole sharedConsole].delegate = self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{	
	[textField resignFirstResponder];
	[self sayHello:self];
	return YES;
}

- (void)handleConsoleCommand:(NSString *)command
{
	if ([command isEqualToString:@"version"])
	{
		[iConsole info:@"%@ version %@",
		 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
		 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	}
	else 
	{
		[iConsole error:@"unrecognised command, try 'version' instead"];
	}
}

- (void)viewDidUnload
{
	self.label = nil;
	self.field = nil;
}

- (void)dealloc
{
	[label release];
	[field release];
    [super dealloc];
}

//I know the method - '-crash:' isn't defined - that's intentional, so that pressing it will cause a crash!

@end
