//
//  QBPopupMenuOverlayView.h
//  QBPopupMenu
//
//  Created by Tanaka Katsuma on 2013/11/24.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import <UIKit/UIKit.h>
#undef weak_safe
#if __has_feature(objc_arc_weak)
#define weak_safe weak
#else
#define weak_safe unsafe_unretained
#endif
@class QBPopupMenu;

@interface QBPopupMenuOverlayView : UIView

@property (nonatomic, weak_safe) QBPopupMenu *popupMenu;

@end
