
#import <UIKit/UIKit.h>
#import "DDLog.h"

// A simple logger for CocoaLumberJack
//
// Add the following to your CocoaLumberJack Initialization code
// [DDLog addLogger:[iConsoleLogger sharedInstance]]; 

@interface iConsoleLogger : DDAbstractLogger <DDLogger>
+ (iConsoleLogger *)sharedInstance;
@end
