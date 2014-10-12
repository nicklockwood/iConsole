//
//  iConsole.h
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

#import <UIKit/UIKit.h>


#import <Availability.h>
#undef weak_delegate
#if __has_feature(objc_arc_weak)
#define weak_delegate weak
#else
#define weak_delegate unsafe_unretained
#endif


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
@property (nonatomic, weak_delegate) id<iConsoleDelegate> delegate;

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
@property (nonatomic, assign) UIScrollViewIndicatorStyle indicatorStyle;

//methods

+ (iConsole *)sharedConsole;

+ (void)log:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void)info:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void)warn:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void)error:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void)crash:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

+ (void)log:(NSString *)format args:(va_list)argList;
+ (void)info:(NSString *)format args:(va_list)argList;
+ (void)warn:(NSString *)format args:(va_list)argList;
+ (void)error:(NSString *)format args:(va_list)argList;
+ (void)crash:(NSString *)format args:(va_list)argList;

+ (void)clear;

+ (void)show;
+ (void)hide;

@end


@interface iConsoleWindow : UIWindow

@end