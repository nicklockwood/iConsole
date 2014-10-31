//
//  QBPopupMenuItemView.h
//  QBPopupMenu
//
//  Created by Tanaka Katsuma on 2013/11/22.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QBPopupMenu;
@class QBPopupMenuItem;

#undef weak_safe
#if __has_feature(objc_arc_weak)
#define weak_safe weak
#else
#define weak_safe unsafe_unretained
#endif

@interface QBPopupMenuItemView : UIView

@property (nonatomic, weak_safe) QBPopupMenu *popupMenu;

@property (nonatomic, strong, readonly) UIButton *button;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *highlightedImage;

@property (nonatomic, strong) QBPopupMenuItem *item;

+ (instancetype)itemViewWithItem:(QBPopupMenuItem *)item;
- (instancetype)initWithItem:(QBPopupMenuItem *)item;

- (void)performAction;

@end
