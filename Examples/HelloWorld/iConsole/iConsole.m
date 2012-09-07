//
//  iConsole.m
//
//  Version 1.3
//
//  Created by Nick Lockwood on 20/12/2010.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from either of these locations:
//
//  http://charcoaldesign.co.uk/source/cocoa#iconsole
//  https://github.com/nicklockwood/iConsole
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "iConsole.h"
#import <stdarg.h>
#import <string.h> 

#if USE_GOOGLE_STACK_TRACE
#import "GTMStackTrace.h"
#endif


#define EDITFIELD_HEIGHT 28
#define INFOBUTTON_WIDTH 20


@interface iConsole() <UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UITextView *consoleView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *infoButton;
@property (nonatomic, strong) NSMutableArray *log;
@property (nonatomic, assign) BOOL animating;

@end


@implementation iConsole

@synthesize delegate;
@synthesize consoleView;
@synthesize inputField;
@synthesize infoButton;
@synthesize log;
@synthesize animating;


#pragma mark -
#pragma mark Private methods

void exceptionHandler(NSException *exception)
{
	NSString *trace;
	
#if USE_GOOGLE_STACK_TRACE
	
	trace = GTMStackTraceFromException(exception);
	
#else
	
	trace = [[exception callStackReturnAddresses] componentsJoinedByString:@"\n"];
	 
#endif
	
	[iConsole crash:@"Stack: (\n%@\n)", trace];

#if SAVE_LOG_TO_DISK
	
	[[iConsole sharedConsole] performSelector:@selector(savePreferences)];
	
#endif
	
}

- (void)setConsoleText
{
	NSString *text = CONSOLE_BRANDING;
	int touches = (TARGET_IPHONE_SIMULATOR ? SIMULATOR_CONSOLE_TOUCHES: DEVICE_CONSOLE_TOUCHES);
	if (touches > 0 && touches < 11)
	{
		text = [text stringByAppendingFormat:@"\nSwipe down with %i finger%@ to hide console", touches, (touches != 1)? @"s": @""];
	}
	else if (TARGET_IPHONE_SIMULATOR ? SIMULATOR_SHAKE_TO_SHOW_CONSOLE: DEVICE_SHAKE_TO_SHOW_CONSOLE)
	{
		text = [text stringByAppendingString:@"\nShake device to hide console"];
	}
	text = [text stringByAppendingString:@"\n--------------------------------------\n"];
	text = [text stringByAppendingString:[log componentsJoinedByString:@"\n"]];
	consoleView.text = text;
	
	[consoleView scrollRangeToVisible:NSMakeRange(consoleView.text.length, 0)];
}

- (void)resetLog
{
	self.log = [NSMutableArray arrayWithObjects:@"> ", nil];
	[self setConsoleText];
}

- (void)savePreferences
{
	[[NSUserDefaults standardUserDefaults] setObject:self.log forKey:@"iConsoleLog"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)findAndResignFirstResponder:(UIView *)view
{
    if ([view isFirstResponder])
	{
        [view resignFirstResponder];
        return YES;     
    }
    for (UIView *subview in view.subviews)
	{
        if ([self findAndResignFirstResponder:subview])
        {
			return YES;
		}
    }
    return NO;
}

- (void)infoAction
{
	[self findAndResignFirstResponder:[UIApplication sharedApplication].keyWindow];
	
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@""
														delegate:self
											   cancelButtonTitle:@"Cancel"
										  destructiveButtonTitle:@"Clear Log"
											   otherButtonTitles:@"Send by Email", nil] autorelease];
	
	sheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[sheet showInView:self.view];
}

- (CGAffineTransform)viewTransform
{
	CGFloat angle = 0;
	switch ([UIApplication sharedApplication].statusBarOrientation)
    {
        case UIInterfaceOrientationPortrait:
            angle = 0;
            break;
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = -M_PI_2;
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = M_PI_2;
			break;
	}
	return CGAffineTransformMakeRotation(angle);
}

- (CGRect)onscreenFrame
{
	return [UIScreen mainScreen].applicationFrame;
}

- (CGRect)offscreenFrame
{
	CGRect frame = [self onscreenFrame];
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationPortrait:
			frame.origin.y = frame.size.height;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			frame.origin.y = -frame.size.height;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			frame.origin.x = frame.size.width;
			break;
		case UIInterfaceOrientationLandscapeRight:
			frame.origin.x = -frame.size.width;
			break;
	}
	return frame;
}

- (void)showConsole
{	
	if (!animating && self.view.superview == nil)
	{
		[self findAndResignFirstResponder:[[UIApplication sharedApplication] keyWindow]];
		
		[iConsole sharedConsole].view.frame = [self offscreenFrame];
		[[[UIApplication sharedApplication] keyWindow] addSubview:[iConsole sharedConsole].view];
		
		animating = YES;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.4];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(consoleShown)];
		[iConsole sharedConsole].view.frame = [self onscreenFrame];
		[UIView commitAnimations];
	}
}

- (void)consoleShown
{
	animating = NO;
	[self findAndResignFirstResponder:[[UIApplication sharedApplication] keyWindow]];
}

- (void)hideConsole
{
	if (!animating && self.view.superview != nil)
	{
		[self findAndResignFirstResponder:[[UIApplication sharedApplication] keyWindow]];
		
		animating = YES;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.4];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(consoleHidden)];
		[iConsole sharedConsole].view.frame = [self offscreenFrame];
		[UIView commitAnimations];
	}
}

- (void)consoleHidden
{
	animating = NO;
	[[[iConsole sharedConsole] view] removeFromSuperview];
}

- (void)rotateView:(NSNotification *)notification
{
	self.view.transform = [self viewTransform];
	self.view.frame = [self onscreenFrame];
	
	if (delegate != nil)
	{
		//workaround for autoresizeing glitch
		CGRect frame = self.view.bounds;
		frame.size.height -= EDITFIELD_HEIGHT + 10;
		self.consoleView.frame = frame;
	}
}

- (void)resizeView:(NSNotification *)notification
{
	CGRect frame = [[notification.userInfo valueForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
	CGRect bounds = [UIScreen mainScreen].bounds;
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationPortrait:
			bounds.origin.y += frame.size.height;
			bounds.size.height -= frame.size.height;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			bounds.size.height -= frame.size.height;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			bounds.origin.x += frame.size.width;
			bounds.size.width -= frame.size.width;
			break;
		case UIInterfaceOrientationLandscapeRight:
			bounds.size.width -= frame.size.width;
			break;
	}
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.35];
	self.view.frame = bounds;
	[UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGRect frame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat duration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	UIViewAnimationCurve curve = [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:curve];
	
	CGRect bounds = [self onscreenFrame];
	switch ([UIApplication sharedApplication].statusBarOrientation) {
		case UIInterfaceOrientationPortrait:
			bounds.size.height -= frame.size.height;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			bounds.origin.y += frame.size.height;
			bounds.size.height -= frame.size.height;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			bounds.size.width -= frame.size.width;
			break;
		case UIInterfaceOrientationLandscapeRight:
			bounds.origin.x += frame.size.width;
			bounds.size.width -= frame.size.width;
			break;
	}
	self.view.frame = bounds;
	
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	CGFloat duration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	UIViewAnimationCurve curve = [[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:duration];
	[UIView setAnimationCurve:curve];
	
	self.view.frame = [self onscreenFrame];	
	
	[UIView commitAnimations];
}

- (void)logOnMainThread:(NSString *)message
{
	[log insertObject:[@"> " stringByAppendingString:message] atIndex:[log count] - 1];
	if ([log count] > MAX_LOG_ITEMS)
	{
		[log removeObjectAtIndex:0];
	}
	[self setConsoleText];
	[consoleView scrollRangeToVisible:NSMakeRange(consoleView.text.length, 0)];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (![textField.text isEqualToString:@""])
	{
		[iConsole log:textField.text];
		[delegate handleConsoleCommand:textField.text];
		textField.text = @"";
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
	return YES;
}


#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.destructiveButtonIndex)
	{
		[iConsole clear];
	}
	else if (buttonIndex == actionSheet.firstOtherButtonIndex)
	{
		NSMutableString *url = [NSMutableString stringWithFormat:@"mailto:%@?subject=%@%%20Console%%20Log&body=",
								LOG_SUBMIT_EMAIL, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
		for (NSString *line in self.log) {
			[url appendString:[line stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			[url appendString:@"%0A"];
		}
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
	}
}


#pragma mark -
#pragma mark Life cycle

+ (void)initialize
{

#if ADD_CRASH_HANDLER
	
	NSSetUncaughtExceptionHandler(&exceptionHandler);
	
#endif
	
}

+ (iConsole *)sharedConsole
{
    @synchronized(self)
    {
    
#if defined CONSOLE_ENABLED && CONSOLE_ENABLED
	
        static iConsole *sharedConsole = nil;
        if (sharedConsole == nil)
        {
            sharedConsole = [[self alloc] init];
        }
        return sharedConsole;
	
#else
	
        return nil
	
#endif
        
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
		[self resetLog];
		
#if SAVE_LOG_TO_DISK
		
		[[NSUserDefaults standardUserDefaults] synchronize];
		NSArray *loadedLog = [[NSUserDefaults standardUserDefaults] objectForKey:@"iConsoleLog"];
		if (loadedLog && [loadedLog count] > 0)
		{
			self.log = [[loadedLog mutableCopy] autorelease];
		}		
		
		if (&UIApplicationDidEnterBackgroundNotification != NULL)
		{
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(savePreferences)
														 name:UIApplicationDidEnterBackgroundNotification
													   object:nil];
		}

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(savePreferences)
													 name:UIApplicationWillTerminateNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rotateView:)
													 name:UIApplicationDidChangeStatusBarOrientationNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resizeView:)
													 name:UIApplicationWillChangeStatusBarFrameNotification
												   object:nil];
#endif
		
	}
	return self;
}

- (void)viewDidLoad
{
	self.view.backgroundColor = CONSOLE_BACKGROUND_COLOR;
	self.view.autoresizesSubviews = YES;

	consoleView = [[UITextView alloc] initWithFrame:self.view.bounds];
	consoleView.font = [UIFont fontWithName:@"Courier" size:12];
	consoleView.textColor = CONSOLE_TEXT_COLOR;
	consoleView.backgroundColor = [UIColor clearColor];
	consoleView.editable = NO;
	consoleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self setConsoleText];
	[self.view addSubview:consoleView];
	
	self.infoButton = [UIButton buttonWithType:CONSOLE_BUTTON_TYPE];
	infoButton.frame = CGRectMake(self.view.frame.size.width - INFOBUTTON_WIDTH - 5,
								  self.view.frame.size.height - EDITFIELD_HEIGHT - 5,
								  INFOBUTTON_WIDTH, EDITFIELD_HEIGHT);
	[infoButton addTarget:self action:@selector(infoAction) forControlEvents:UIControlEventTouchUpInside];
	infoButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
	[self.view addSubview:infoButton];
	
	if (delegate)
	{
		inputField = [[UITextField alloc] initWithFrame:CGRectMake(5, self.view.frame.size.height - EDITFIELD_HEIGHT - 5,
																   self.view.frame.size.width - 15 - INFOBUTTON_WIDTH,
																   EDITFIELD_HEIGHT)];
		inputField.borderStyle = UITextBorderStyleRoundedRect;
		inputField.font = [UIFont fontWithName:@"Courier" size:12];
		inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		inputField.autocorrectionType = UITextAutocorrectionTypeNo;
		inputField.returnKeyType = UIReturnKeyDone;
		inputField.enablesReturnKeyAutomatically = NO;
		inputField.clearButtonMode = UITextFieldViewModeWhileEditing;
		inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		inputField.placeholder = CONSOLE_INPUT_PLACEHOLDER;
		inputField.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		inputField.delegate = self;
		CGRect frame = self.view.bounds;
		frame.size.height -= EDITFIELD_HEIGHT + 10;
		consoleView.frame = frame;
		[self.view addSubview:inputField];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillShow:)
													 name:UIKeyboardWillShowNotification
												   object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillHide:)
													 name:UIKeyboardWillHideNotification
												   object:nil];
	}

	[self.consoleView scrollRangeToVisible:NSMakeRange(self.consoleView.text.length, 0)];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	self.consoleView = nil;
	self.inputField = nil;
	self.infoButton = nil;
    
    [super viewDidUnload];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[consoleView release];
	[inputField release];
	[infoButton release];
	[log release];
    
	[super ah_dealloc];
}


#pragma mark -
#pragma mark Public methods

+ (void)log:(NSString *)format arguments:(va_list)argList
{	
	NSString *message = [[[NSString alloc] initWithFormat:format arguments:argList] autorelease];
	NSLog(@"%@", message);
	
#if defined CONSOLE_ENABLED && CONSOLE_ENABLED
	
	if ([NSThread currentThread] == [NSThread mainThread])
	{	
		[[self sharedConsole] logOnMainThread:message];
	}
	else
	{
		[[self sharedConsole] performSelectorOnMainThread:@selector(logOnMainThread:) withObject:message waitUntilDone:NO];
	}
	
#endif

}

+ (void)log:(NSString *)format, ...
{

#if LOG_LEVEL > LOG_LEVEL_NONE
	
	va_list argList;
	va_start(argList,format);
	[self log:format arguments:argList];
	va_end(argList);
	
#endif
	
}

+ (void)info:(NSString *)format, ...
{
	
#if LOG_LEVEL >= LOG_LEVEL_INFO
	
	va_list argList;
	va_start(argList, format);
	[self log:[@"INFO: " stringByAppendingString:format] arguments:argList];
	va_end(argList);
	
#endif
	
}

+ (void)warn:(NSString *)format, ...
{
	
#if LOG_LEVEL >= LOG_LEVEL_WARNING
	
	va_list argList;
	va_start(argList, format);
	[self log:[@"WARNING: " stringByAppendingString:format] arguments:argList];
	va_end(argList);
	
#endif

}

+ (void)error:(NSString *)format, ...
{
	
#if LOG_LEVEL >= LOG_LEVEL_ERROR
	
	va_list argList;
	va_start(argList, format);
	[self log:[@"ERROR: " stringByAppendingString:format] arguments:argList];
	va_end(argList);
	
#endif
	
}

+ (void)crash:(NSString *)format, ...
{
	
#if LOG_LEVEL >= LOG_LEVEL_CRASH
	
	va_list argList;
	va_start(argList, format);
	[self log:[@"CRASH: " stringByAppendingString:format] arguments:argList];
	va_end(argList);
	
#endif
	
}

+ (void)clear
{
	[[iConsole sharedConsole] resetLog];
}

+ (void)show
{
	[[iConsole sharedConsole] showConsole];
}

+ (void)hide
{
	[[iConsole sharedConsole] hideConsole];
}

@end


@implementation iConsoleWindow

#if defined CONSOLE_ENABLED && CONSOLE_ENABLED

+ (void)initialize
{
	//initialise the console
	[iConsole sharedConsole];
}

- (void)sendEvent:(UIEvent *)event
{
	if (event.type == UIEventTypeTouches)
	{
		NSSet *touches = [event allTouches];
		if ([touches count] == (TARGET_IPHONE_SIMULATOR ? SIMULATOR_CONSOLE_TOUCHES: DEVICE_CONSOLE_TOUCHES))
		{
			BOOL allUp = YES;
			BOOL allDown = YES;
			BOOL allLeft = YES;
			BOOL allRight = YES;
			
			for (UITouch *touch in touches)
			{
				if ([touch locationInView:self].y <= [touch previousLocationInView:self].y)
				{
					allDown = NO;
				}
				if ([touch locationInView:self].y >= [touch previousLocationInView:self].y)
				{
					allUp = NO;
				}
				if ([touch locationInView:self].x <= [touch previousLocationInView:self].x)
				{
					allLeft = NO;
				}
				if ([touch locationInView:self].x >= [touch previousLocationInView:self].x)
				{
					allRight = NO;
				}
			}
			
			switch ([UIApplication sharedApplication].statusBarOrientation) {
				case UIInterfaceOrientationPortrait:
					if (allUp)
					{
						[iConsole show];
						return;
					}
					else if (allDown)
					{
						[iConsole hide];
						return;
					}
					break;
				case UIInterfaceOrientationPortraitUpsideDown:
					if (allDown)
					{
						[iConsole show];
						return;
					}
					else if (allUp)
					{
						[iConsole hide];
						return;
					}
					break;
				case UIInterfaceOrientationLandscapeLeft:
					if (allRight)
					{
						[iConsole show];
						return;
					}
					else if (allLeft)
					{
						[iConsole hide];
						return;
					}
					break;
				case UIInterfaceOrientationLandscapeRight:
					if (allLeft)
					{
						[iConsole show];
						return;
					}
					else if (allRight)
					{
						[iConsole hide];
						return;
					}
					break;
			}
		}
	}
    
	return [super sendEvent:event];
}

#	if (TARGET_IPHONE_SIMULATOR ? SIMULATOR_SHAKE_TO_SHOW_CONSOLE: DEVICE_SHAKE_TO_SHOW_CONSOLE)

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake)
	{
		if ([iConsole sharedConsole].view.superview == nil)
		{
			[iConsole show];
		}
		else
		{
			[iConsole hide];
		}
    }
	
	[super motionEnded:motion withEvent:event];
}

#	endif

#endif

@end
