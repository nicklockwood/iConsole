//
//  QBPopupMenuPagenatorView.h
//  QBPopupMenu
//
//  Created by Tanaka Katsuma on 2013/11/23.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "QBPopupMenuItemView.h"

typedef NS_ENUM(NSUInteger, QBPopupMenuPagenatorDirection) {
    QBPopupMenuPagenatorDirectionLeft,
    QBPopupMenuPagenatorDirectionRight
};

#undef weak_safe
#if __has_feature(objc_arc_weak)
#define weak_safe weak
#else
#define weak_safe unsafe_unretained
#endif

@interface QBPopupMenuPagenatorView : QBPopupMenuItemView

@property (nonatomic, weak_safe) id target;
@property (nonatomic, assign) SEL action;

+ (CGFloat)pagenatorWidth;

+ (instancetype)leftPagenatorViewWithTarget:(id)target action:(SEL)action;
+ (instancetype)rightPagenatorViewWithTarget:(id)target action:(SEL)action;

- (instancetype)initWithArrowDirection:(QBPopupMenuPagenatorDirection)arrowDirection target:(id)target action:(SEL)action;

// NOTE: When subclassing this class, use these methods to customize the appearance.
- (CGMutablePathRef)arrowPathInRect:(CGRect)rect direction:(QBPopupMenuPagenatorDirection)direction CF_RETURNS_RETAINED;
- (void)drawArrowInRect:(CGRect)rect direction:(QBPopupMenuPagenatorDirection)direction highlighted:(BOOL)highlighted;

@end
