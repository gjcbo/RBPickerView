//
//  WSDatePickerView.h
//  WSDatePicker
//
//  Created by iMac on 17/2/23.
//  Copyright © 2017年 zws. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum{
    DateStyleShowYearMonthDayHourMinute  = 0,
    DateStyleShowMonthDayHourMinute,
    DateStyleShowYearMonthDay,
    DateStyleShowMonthDay,
    DateStyleShowHourMinute
    
}WSDateStyle;


@interface WSDatePickerView : UIView

@property (nonatomic,assign)WSDateStyle datePickerStyle;
@property (nonatomic,strong)UIColor *themeColor;

//rb 1-18  最好的是把这两个东西封装起来，不暴露，提供两个方法，对这两个属性进行赋值。只需要默认的进行一次赋值，没必要重写set方法。一方面会导致方法重复调用，二如果一个变量被反复的赋值，导致别人看不懂你的代码，或者必须花好长时间才能看懂你的代码还要借助终端反复的调试才能搞明白。降低可读性，不利于后期维护。 还有方法命名的时候尽量不要用与系统相同的方法名。 什么set、get new 一看到这个东西，就以为是系统的，妈的其实是自定的方法，还有一个问题，如果你使用new系统就会给你提示，不能用。不要用系统的名字。
@property (nonatomic, retain) NSDate *maxLimitDate;//限制最大时间（没有设置默认2049）
@property (nonatomic, retain) NSDate *minLimitDate;//限制最小时间（没有设置默认1970）

-(instancetype)initWithCompleteBlock:(void(^)(NSDate *))completeBlock;

/**给最小值赋值，只用一次，不建议重写系统的maxLimitDate set方法*/
- (void)rb_AssignMinLimitDate:(NSDate *)minLimitDate;


-(void)show;


@end
