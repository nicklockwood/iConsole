//
//  iConsoleManager.h
//  HelloWorld
//
//  Created by Vienta on 5/29/14.
//
//

#import <Foundation/Foundation.h>
#import "QBPopupMenu.h"
#import "iConsole.h"

typedef NS_ENUM(NSUInteger, CMDType){
    CMDTypeFind = 1,
    CMDTypeVersion
};


@interface iConsoleManager : NSObject<iConsoleDelegate>

@property (nonatomic, strong) QBPopupMenu *commandMenu;
@property (nonatomic, readwrite) NSMutableArray *commandItems;
@property (nonatomic, assign) CMDType cmdType;
@property (nonatomic, assign) BOOL openCMD; //decide whether open the command 

+ (instancetype)sharediConsoleManager;

@end
