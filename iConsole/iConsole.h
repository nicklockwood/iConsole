//
//  iConsole.h
//
//  Version 1.4.1
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

//
//  ARC Helper
//
//  Version 2.1
//
//  Created by Nick Lockwood on 05/01/2012.
//  Copyright 2012 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://gist.github.com/1563325
//

#ifndef ah_retain
#if __has_feature(objc_arc)
#define ah_retain self
#define ah_dealloc self
#define release self
#define autorelease self
#else
#define ah_retain retain
#define ah_dealloc dealloc
#define __bridge
#endif
#endif

//  Weak reference support

#import <Availability.h>
#if (!__has_feature(objc_arc)) || \
(defined __IPHONE_OS_VERSION_MIN_REQUIRED && \
__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0) || \
(defined __MAC_OS_X_VERSION_MIN_REQUIRED && \
__MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_7)
#undef weak
#define weak unsafe_unretained
#undef __weak
#define __weak __unsafe_unretained
#endif

//  ARC Helper ends

#import <UIKit/UIKit.h>


#define ICONSOLE_ADD_EXCEPTION_HANDLER 1 //add automatic crash logging
#define ICONSOLE_USE_GOOGLE_STACK_TRACE 1 //use GTM functions to improve stack trace


typedef enum
{
    iConsoleLogLevelNone = 0,
    iConsoleLogLevelCrash,
    iConsoleLogLevelError,
    iConsoleLogLevelWarning,
    iConsoleLogLevelInfo
}
iConsoleLogLevel;


@protocol iConsoleDelegate <NSObject>

- (void)handleConsoleCommand:(NSString *)command;

@end


@interface iConsole : UIViewController

//enabled/disable console features

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL saveLogToDisk;
@property (nonatomic, assign) NSUInteger maxLogItems;
@property (nonatomic, assign) iConsoleLogLevel logLevel;
@property (nonatomic, weak) id<iConsoleDelegate> delegate;

//console activation

@property (nonatomic, assign) NSUInteger simulatorTouchesToShow;
@property (nonatomic, assign) NSUInteger deviceTouchesToShow;
@property (nonatomic, assign) BOOL simulatorShakeToShow;
@property (nonatomic, assign) BOOL deviceShakeToShow;

//branding and feedback

@property (nonatomic, copy) NSString *infoString;
@property (nonatomic, copy) NSString *inputPlaceholderString;
@property (nonatomic, copy) NSString *logSubmissionEmail;

//styling

@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *textColor;

//methods

+ (iConsole *)sharedConsole;

+ (void)log:(NSString *)format, ...;
+ (void)info:(NSString *)format, ...;
+ (void)warn:(NSString *)format, ...;
+ (void)error:(NSString *)format, ...;
+ (void)crash:(NSString *)format, ...;

+ (void)clear;

+ (void)show;
+ (void)hide;

@end


@interface iConsoleWindow : UIWindow

@end