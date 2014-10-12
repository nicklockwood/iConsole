//
//  iConsole.m
//
//  Version 1.5.3
//
//  Created by Nick Lockwood on 20/12/2010.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
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
#import <TargetConditionals.h>


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


#if ICONSOLE_USE_GOOGLE_STACK_TRACE
#import "GTMStackTrace.h"
#endif


#define EDITFIELD_HEIGHT 28
#define ACTION_BUTTON_WIDTH 28


@interface iConsole() <UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UITextView *consoleView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) NSMutableArray *log;
@property (nonatomic, assign) BOOL animating;

- (void)saveSettings;

@end


@implementation iConsole

#pragma mark -
#pragma mark Private methods

static void exceptionHandler(NSException *exception)
{
	
#if ICONSOLE_USE_GOOGLE_STACK_TRACE
	
    extern NSString *GTMStackTraceFromException(NSException *e);
    [iConsole crash:@"%@\n\nStack trace:\n%@)", exception, GTMStackTraceFromException(exception)];
	
#else
	
	[iConsole crash:@"%@", exception];
	 
#endif

	[[iConsole sharedConsole] saveSettings];
}

+ (void)load
{
    //initialise the console
    [iConsole performSelectorOnMainThread:@selector(sharedConsole) withObject:nil waitUntilDone:NO];
}

- (UIWindow *)mainWindow
{
    UIApplication *app = [UIApplication sharedApplication];
    if ([app.delegate respondsToSelector:@selector(window)])
    {
        return [app.delegate window];
    }
    else
    {
        return [app keyWindow];
    }
}

- (void)setConsoleText
{
	NSString *text = _infoString;
	NSUInteger touches = (TARGET_IPHONE_SIMULATOR ? _simulatorTouchesToShow: _deviceTouchesToShow);
	if (touches > 0 && touches < 11)
	{
		text = [text stringByAppendingFormat:@"\nSwipe down with %zd finger%@ to hide console", touches, (touches != 1)? @"s": @""];
	}
	else if (TARGET_IPHONE_SIMULATOR ? _simulatorShakeToShow: _deviceShakeToShow)
	{
		text = [text stringByAppendingString:@"\nShake device to hide console"];
	}
	text = [text stringByAppendingString:@"\n--------------------------------------\n"];
	text = [text stringByAppendingString:[[_log arrayByAddingObject:@">"] componentsJoinedByString:@"\n"]];
	_consoleView.text = text;
	
	[_consoleView scrollRangeToVisible:NSMakeRange(_consoleView.text.length, 0)];
}

- (void)resetLog
{
	self.log = [NSMutableArray array];
	[self setConsoleText];
}

- (void)saveSettings
{
    if (_saveLogToDisk)
    {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
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
	[self findAndResignFirstResponder:[self mainWindow]];
	
    //note: we can't use UIAlertController because we don't have a UIViewController
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:@"Clear Log"
                                              otherButtonTitles:@"Send by Email", @"Close Console", nil];

    sheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [sheet showInView:self.view];
}

- (CGAffineTransform)viewTransform
{
	CGFloat angle = 0;
	switch ([UIApplication sharedApplication].statusBarOrientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
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
	switch ([UIApplication sharedApplication].statusBarOrientation)
    {
		case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
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
	if (!_animating && self.view.superview == nil)
	{
        [self setConsoleText];
        
		[self findAndResignFirstResponder:[self mainWindow]];
		
		[iConsole sharedConsole].view.frame = [self offscreenFrame];
		[[self mainWindow] addSubview:[iConsole sharedConsole].view];
		
		_animating = YES;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.4];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(consoleShown)];
		[iConsole sharedConsole].view.frame = [self onscreenFrame];
        [iConsole sharedConsole].view.transform = [self viewTransform];
		[UIView commitAnimations];
	}
}

- (void)consoleShown
{
	_animating = NO;
	[self findAndResignFirstResponder:[self mainWindow]];
}

- (void)hideConsole
{
	if (!_animating && self.view.superview != nil)
	{
		[self findAndResignFirstResponder:[self mainWindow]];
		
		_animating = YES;
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
	_animating = NO;
	[[[iConsole sharedConsole] view] removeFromSuperview];
}

- (void)rotateView:(NSNotification *)notification
{
	self.view.transform = [self viewTransform];
	self.view.frame = [self onscreenFrame];
	
	if (_delegate != nil)
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
	switch ([UIApplication sharedApplication].statusBarOrientation)
    {
		case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
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
	switch ([UIApplication sharedApplication].statusBarOrientation)
    {
		case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
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
	[_log addObject:[@"> " stringByAppendingString:message]];
	if ([_log count] > _maxLogItems)
	{
		[_log removeObjectAtIndex:0];
	}
    [[NSUserDefaults standardUserDefaults] setObject:_log forKey:@"iConsoleLog"];
    if (self.view.superview)
    {
        [self setConsoleText];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (![textField.text isEqualToString:@""])
	{
		[iConsole log:@"%@", textField.text];
		[_delegate handleConsoleCommand:textField.text];
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

- (NSString *)URLEncodedString:(NSString *)string
{
    return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, CFSTR("!*'\"();:@&=+$,/?%#[]% "), kCFStringEncodingUTF8));
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.destructiveButtonIndex)
	{
		[iConsole clear];
	}
	else if (buttonIndex != actionSheet.cancelButtonIndex)
	{
        if (buttonIndex == 1)
        {
            NSString *URLSafeName = [self URLEncodedString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]];
            NSString *URLSafeLog = [self URLEncodedString:[_log componentsJoinedByString:@"\n"]];
            NSMutableString *URLString = [NSMutableString stringWithFormat:@"mailto:%@?subject=%@%%20Console%%20Log&body=%@",
                                          _logSubmissionEmail ?: @"", URLSafeName, URLSafeLog];

            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
        }
        else
        {
            [self hideConsole];
        }
	}
}


#pragma mark -
#pragma mark Life cycle

+ (iConsole *)sharedConsole
{
    @synchronized(self)
    {
        static iConsole *sharedConsole = nil;
        if (sharedConsole == nil)
        {
            sharedConsole = [[self alloc] init];
        }
        return sharedConsole; 
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
        
#if ICONSOLE_ADD_EXCEPTION_HANDLER
        
        NSSetUncaughtExceptionHandler(&exceptionHandler);
        
#endif
        
        _enabled = YES;
        _logLevel = iConsoleLogLevelInfo;
        _saveLogToDisk = YES;
        _maxLogItems = 1000;
        _delegate = nil;
        
        _simulatorTouchesToShow = 2;
        _deviceTouchesToShow = 3;
        _simulatorShakeToShow = YES;
        _deviceShakeToShow = YES;
        
        self.infoString = @"iConsole: Copyright © 2010 Charcoal Design";
        self.inputPlaceholderString = @"Enter command...";
        self.logSubmissionEmail = nil;
        
        self.backgroundColor = [UIColor blackColor];
        self.textColor = [UIColor whiteColor];
        self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.log = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"iConsoleLog"]];
        
        if (&UIApplicationDidEnterBackgroundNotification != NULL)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(saveSettings)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveSettings)
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
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.clipsToBounds = YES;
	self.view.backgroundColor = _backgroundColor;
	self.view.autoresizesSubviews = YES;

	_consoleView = [[UITextView alloc] initWithFrame:self.view.bounds];
	_consoleView.font = [UIFont fontWithName:@"Courier" size:12];
	_consoleView.textColor = _textColor;
	_consoleView.backgroundColor = [UIColor clearColor];
    _consoleView.indicatorStyle = _indicatorStyle;
	_consoleView.editable = NO;
	_consoleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self setConsoleText];
	[self.view addSubview:_consoleView];
	
	self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_actionButton setTitle:@"⚙" forState:UIControlStateNormal];
    [_actionButton setTitleColor:_textColor forState:UIControlStateNormal];
    [_actionButton setTitleColor:[_textColor colorWithAlphaComponent:0.5f] forState:UIControlStateHighlighted];
    _actionButton.titleLabel.font = [_actionButton.titleLabel.font fontWithSize:ACTION_BUTTON_WIDTH];
	_actionButton.frame = CGRectMake(self.view.frame.size.width - ACTION_BUTTON_WIDTH - 5,
                                   self.view.frame.size.height - EDITFIELD_HEIGHT - 5,
                                   ACTION_BUTTON_WIDTH, EDITFIELD_HEIGHT);
	[_actionButton addTarget:self action:@selector(infoAction) forControlEvents:UIControlEventTouchUpInside];
	_actionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
	[self.view addSubview:_actionButton];
	
	if (_delegate)
	{
		_inputField = [[UITextField alloc] initWithFrame:CGRectMake(5, self.view.frame.size.height - EDITFIELD_HEIGHT - 5,
                                                                    self.view.frame.size.width - 15 - ACTION_BUTTON_WIDTH,
                                                                    EDITFIELD_HEIGHT)];
		_inputField.borderStyle = UITextBorderStyleRoundedRect;
		_inputField.font = [UIFont fontWithName:@"Courier" size:12];
		_inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_inputField.autocorrectionType = UITextAutocorrectionTypeNo;
		_inputField.returnKeyType = UIReturnKeyDone;
		_inputField.enablesReturnKeyAutomatically = NO;
		_inputField.clearButtonMode = UITextFieldViewModeWhileEditing;
		_inputField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		_inputField.placeholder = _inputPlaceholderString;
		_inputField.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		_inputField.delegate = self;
		CGRect frame = self.view.bounds;
		frame.size.height -= EDITFIELD_HEIGHT + 10;
		_consoleView.frame = frame;
		[self.view addSubview:_inputField];
		
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
	self.actionButton = nil;
    
    [super viewDidUnload];
}


#pragma mark -
#pragma mark Public methods

+ (void)log:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    [self log:format args:argList];
    va_end(argList);
}

+ (void)info:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    [self info:format args:argList];
    va_end(argList);
}

+ (void)warn:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    [self warn:format args:argList];
    va_end(argList);
}

+ (void)error:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    [self error:format args:argList];
    va_end(argList);
}

+ (void)crash:(NSString *)format, ...
{
    va_list argList;
    va_start(argList, format);
    [self crash:format args:argList];
    va_end(argList);
}

+ (void)log:(NSString *)format args:(va_list)argList
{
    if ([self sharedConsole].logLevel > iConsoleLogLevelNone)
    {
        NSString *message = [(NSString *)[NSString alloc] initWithFormat:format arguments:argList];
        
        NSLog(@"%@", message);
        
        if ([self sharedConsole].enabled)
        {
            if ([NSThread currentThread] == [NSThread mainThread])
            {
                [[self sharedConsole] logOnMainThread:message];
            }
            else
            {
                [[self sharedConsole] performSelectorOnMainThread:@selector(logOnMainThread:)
                                                       withObject:message waitUntilDone:NO];
            }
        }
    }
}

+ (void)info:(NSString *)format args:(va_list)argList
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelInfo)
    {
        [self log:[@"INFO: " stringByAppendingString:format] args:argList];
    }
}

+ (void)warn:(NSString *)format args:(va_list)argList
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelWarning)
    {
        [self log:[@"WARNING: " stringByAppendingString:format] args:argList];
    }
}

+ (void)error:(NSString *)format args:(va_list)argList
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelError)
    {
        [self log:[@"ERROR: " stringByAppendingString:format] args:argList];
    }
}

+ (void)crash:(NSString *)format args:(va_list)argList
{
    if ([self sharedConsole].logLevel >= iConsoleLogLevelCrash)
    {
        [self log:[@"CRASH: " stringByAppendingString:format] args:argList];
    }
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

- (void)sendEvent:(UIEvent *)event
{
	if ([iConsole sharedConsole].enabled && event.type == UIEventTypeTouches)
	{
		NSSet *touches = [event allTouches];
		if ([touches count] == (TARGET_IPHONE_SIMULATOR ? [iConsole sharedConsole].simulatorTouchesToShow: [iConsole sharedConsole].deviceTouchesToShow))
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
			
			switch ([UIApplication sharedApplication].statusBarOrientation)
            {
				case UIInterfaceOrientationPortrait:
                case UIInterfaceOrientationUnknown:
                {
					if (allUp)
					{
						[iConsole show];
					}
					else if (allDown)
					{
						[iConsole hide];
					}
					break;
                }
				case UIInterfaceOrientationPortraitUpsideDown:
                {
					if (allDown)
					{
						[iConsole show];
					}
					else if (allUp)
					{
						[iConsole hide];
					}
					break;
                }
				case UIInterfaceOrientationLandscapeLeft:
                {
					if (allRight)
					{
						[iConsole show];
					}
					else if (allLeft)
					{
						[iConsole hide];
					}
					break;
                }
				case UIInterfaceOrientationLandscapeRight:
                {
					if (allLeft)
					{
						[iConsole show];
					}
					else if (allRight)
					{
						[iConsole hide];
					}
					break;
                }
			}
		}
	}
	return [super sendEvent:event];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	
    if ([iConsole sharedConsole].enabled &&
        (TARGET_IPHONE_SIMULATOR ? [iConsole sharedConsole].simulatorShakeToShow: [iConsole sharedConsole].deviceShakeToShow))
    {
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
	}
	[super motionEnded:motion withEvent:event];
}

@end
