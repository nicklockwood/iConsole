//
//  iConsoleManager.h
//  HelloWorld
//
//  Created by Vienta on 5/29/14.
//
//

#import <Foundation/Foundation.h>
#import "iConsolePopupMenu.h"
#import "iConsole.h"

typedef NS_ENUM(NSUInteger, CMDType){
    CMDTypeFind = 1,
};


@interface iConsoleManager : NSObject<iConsoleDelegate>

@property (nonatomic, strong) iConsolePopupMenu *commandMenu;
@property (nonatomic, readwrite) NSMutableArray *commandItems;
@property (nonatomic, assign) CMDType cmdType;
@property (nonatomic, assign) BOOL openCMD; //decide whether open the command 

+ (instancetype)sharediConsoleManager;

@end
