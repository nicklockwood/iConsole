//
//  iConsoleManager.m
//  HelloWorld
//
//  Created by Vienta on 5/29/14.
//
//

#import "iConsoleManager.h"
#import "QBPopupMenuItem.h"

@implementation iConsoleManager


+ (instancetype)sharediConsoleManager
{
    static dispatch_once_t pred = 0;
    __strong static id sharediConsoleManager = nil;
    dispatch_once(&pred,^{
            sharediConsoleManager = [[self alloc] init];
        });
    return sharediConsoleManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        self.cmdType = CMDTypeFind;
        self.openCMD = YES;
        
        self.commandItems = [NSMutableArray arrayWithObjects:({
            QBPopupMenuItem *item1 = [QBPopupMenuItem itemWithTitle:@"Find" target:[iConsole sharedConsole] action:@selector(commandAction:)];
            item1;
        }),nil];
        
        self.commandMenu = ({
            QBPopupMenu *menu = [[QBPopupMenu alloc] initWithItems:self.commandItems];
            menu.color = [UIColor grayColor];
            menu.highlightedColor = [[UIColor colorWithRed:0 green:0.478 blue:1.0 alpha:1.0] colorWithAlphaComponent:0.8];
            menu;
        });
    }
    return self;
}

- (void)setOpenCMD:(BOOL)openCMD
{
    _openCMD = openCMD;
    if (_openCMD) {
        [iConsole sharedConsole].delegate = (id)self;
    } else {
        [iConsole sharedConsole].delegate = nil;
    }
}



#pragma mark iConsoleDelegate
- (void)handleConsoleCommand:(NSString *)command
{
    
}

@end
