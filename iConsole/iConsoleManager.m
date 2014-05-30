//
//  iConsoleManager.m
//  HelloWorld
//
//  Created by Vienta on 5/29/14.
//
//

#import "iConsoleManager.h"
#import "iConsolePopupMenuItem.h"

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
            iConsolePopupMenuItem *item1 = [iConsolePopupMenuItem itemWithTitle:@"Find" target:self action:@selector(commandAction:)];
            item1;
        }),nil];
        
        self.commandMenu = ({
            iConsolePopupMenu *menu = [[iConsolePopupMenu alloc] initWithItems:self.commandItems];
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

- (void)commandAction:(id)sender
{
    self.cmdType = CMDTypeFind;
}

#pragma mark iConsoleDelegate
- (void)handleConsoleCommand:(NSString *)command
{
    
}

@end
