//
//  iConsoleWindow.m
//  iConsole
//
//  Created by Nick Lockwood on 20/12/2010.
//  Copyright 2010 Charcoal Design. All rights reserved.
//

#import "iConsoleWindow.h"
#import "iConsole.h"


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
			}
			
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
