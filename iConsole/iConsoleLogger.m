#import "iConsoleLogger.h"
#import "iConsole.h"

@implementation iConsoleLogger

static iConsoleLogger *sharedInstance;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
        [iConsole sharedConsole];
		sharedInstance = [[iConsoleLogger alloc] init];
	}
}

+ (iConsoleLogger *)sharedInstance
{
	return sharedInstance;
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    if (logMessage->logFlag == LOG_FLAG_INFO) {
        [iConsole info:logMessage->logMsg];
    } else if (logMessage->logFlag == LOG_FLAG_WARN) {
        [iConsole warn:logMessage->logMsg];
    } else if (logMessage->logFlag == LOG_FLAG_ERROR) {
        [iConsole error:logMessage->logMsg];
    } else if (logMessage->logFlag == LOG_FLAG_VERBOSE) {
        [iConsole log:[NSString stringWithFormat:@"DEBUG: %@", logMessage->logMsg]];
    } else {
        [iConsole log:[NSString stringWithFormat:@"NOISY: %@", logMessage->logMsg]];
    }
}

@end
