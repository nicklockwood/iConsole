#import "iConsoleLogger.h"
#import "iConsole.h"

@interface iConsoleLogger()
{
    NSCalendar *calendar;
    NSUInteger calendarUnitFlags;
}
@end

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

-(id)init {
    self = [super init];
    
    if (self) {
        calendar = [NSCalendar autoupdatingCurrentCalendar];

        calendarUnitFlags = 0;
        calendarUnitFlags |= NSYearCalendarUnit;
        calendarUnitFlags |= NSMonthCalendarUnit;
        calendarUnitFlags |= NSDayCalendarUnit;
        calendarUnitFlags |= NSHourCalendarUnit;
        calendarUnitFlags |= NSMinuteCalendarUnit;
        calendarUnitFlags |= NSSecondCalendarUnit;
    }
    
    return self;
}

+ (iConsoleLogger *)sharedInstance
{
	return sharedInstance;
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    NSDateComponents *components = [calendar components:calendarUnitFlags fromDate:logMessage->timestamp];
    
    NSTimeInterval epoch = [logMessage->timestamp timeIntervalSinceReferenceDate];
    int milliseconds = (int)((epoch - floor(epoch)) * 1000);

    char ts[24];
    snprintf(ts, 24, "%04ld-%02ld-%02ld %02ld:%02ld:%02ld.%03d", // yyyy-MM-dd HH:mm:ss:SSS
             (long)components.year,
             (long)components.month,
             (long)components.day,
             (long)components.hour,
             (long)components.minute,
             (long)components.second, milliseconds);
    
    if (logMessage->logFlag == LOG_FLAG_INFO) {
        [iConsole log:[NSString stringWithFormat:@"%s INFO: %@", ts, logMessage->logMsg]];
    } else if (logMessage->logFlag == LOG_FLAG_WARN) {
        [iConsole log:[NSString stringWithFormat:@"%s WARN: %@", ts, logMessage->logMsg]];
    } else if (logMessage->logFlag == LOG_FLAG_ERROR) {
        [iConsole log:[NSString stringWithFormat:@"%s ERROR: %@", ts, logMessage->logMsg]];
    } else if (logMessage->logFlag == LOG_FLAG_VERBOSE) {
        [iConsole log:[NSString stringWithFormat:@"%s DEBUG: %@", ts, logMessage->logMsg]];
    } else {
        [iConsole log:[NSString stringWithFormat:@"%s NOISY: %@", ts, logMessage->logMsg]];
    }
}

@end
