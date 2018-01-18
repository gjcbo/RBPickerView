//
//  RBDatePickerView.h
//  RBDatePickerView
//
//  Created by RaoBo on 2018/1/5.
//  Copyright © 2018年 RaoBo. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,RBDateStyle) {
    RBDateStyleYearMonthDayHourMinute = 0, // 1.年月日时分
    RBDateStyleYearMonthDay, // 2.年月日
    RBDateStyleMonthDay, //3.月日
    RBDateStyleHourMinute //4.时分
};

// 选择日期的回调
typedef void(^CompleteBlock)(NSDate *selectedDate);

@interface RBDatePickerView : UIView

/**1.主题颜色*/
@property(nonatomic, strong) UIColor *themeColor;
/**2.显示日期类型*/
@property(nonatomic, assign) RBDateStyle datePickerStyle;

//- (instancetype)initWithCompleteBlock:(void(*)(NSDate *selectDate))block;
- (instancetype)initWithCompleteBlock:(CompleteBlock)compBlock;

/**1. 显示*/
- (void)rb_show;

/**2. 给默认最小日期赋值*/
- (void)rb_AssignMinLimitDate:(NSDate *)minDate;
/** 有两个问题
 2.1  bug❌ 如果外界不传值你怎么办？
 2.2  这个方法必须在创建的时候默认调用一次，如果这个方法后于 rb_show 调用就会导致崩溃。
 */

/**3. 给默认最大日期赋值*/
- (void)rb_AssignMaxLimitDate:(NSDate *)maxDate;
@end
