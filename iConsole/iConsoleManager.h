//
//  iConsoleManager.h
//  HelloWorld
//
//  Created by Vienta on 5/29/14.
//
//

#import <Foundation/Foundation.h>
#import "iConsolePopupMenu.h"


typedef NS_ENUM(NSUInteger, CMDType){
    CMDTypeFind = 1,
};


@interface iConsoleManager : NSObject

@property (nonatomic, strong) iConsolePopupMenu *commandMenu;
@property (nonatomic, readwrite) NSMutableArray *commandItems;
@property (nonatomic, assign) CMDType cmdType;

+ (instancetype)sharediConsoleManager;

@end
