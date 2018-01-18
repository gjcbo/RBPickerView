//
//  WSDatePickerView.m
//  WSDatePicker
//
//  Created by iMac on 17/2/23.
//  Copyright © 2017年 zws. All rights reserved.

#import "WSDatePickerView.h"
#import "UIView+Extension.h"
#import "NSDate+Extension.h"


#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kPickerSize self.datePicker.frame.size
#define RGBA(r, g, b, a) ([UIColor colorWithRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:a])
#define RGB(r, g, b) RGBA(r,g,b,1)


#define MAXYEAR 2050
#define MINYEAR 1970

typedef void(^doneBlock)(NSDate *);

@interface WSDatePickerView ()<UIPickerViewDelegate,UIPickerViewDataSource,UIGestureRecognizerDelegate> {
    //日期存储数组
    NSMutableArray *_yearArray;
    NSMutableArray *_monthArray;
    NSMutableArray *_dayArray;
    NSMutableArray *_hourArray;
    NSMutableArray *_minuteArray;
    NSString *_dateFormatter;
    //记录位置
    NSInteger yearIndex;
    NSInteger monthIndex;
    NSInteger dayIndex;
    NSInteger hourIndex;
    NSInteger minuteIndex;
    
    NSInteger preRow; // ？
    
    NSDate *_startDate;
}
@property (weak, nonatomic) IBOutlet UIView *buttomView;
@property (weak, nonatomic) IBOutlet UILabel *showYearLabel;//显示年份的label
@property (weak, nonatomic) IBOutlet UIButton *doneBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint; // 约束线

- (IBAction)doneAction:(UIButton *)btn;


@property (nonatomic,strong)UIPickerView *datePicker; // rb_日期选择器
@property (nonatomic, retain) NSDate *scrollToDate;//滚到指定日期
@property (nonatomic,strong)doneBlock doneBlock;


@end

@implementation WSDatePickerView

-(instancetype)initWithCompleteBlock:(void(^)(NSDate *))completeBlock {
    self = [super init];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] lastObject];
        
        _dateFormatter = @"yyyy-MM-dd HH:mm";
        [self setupUI];
        [self defaultConfig];
        
        if (completeBlock) {
            self.doneBlock = ^(NSDate *startDate) {
                completeBlock(startDate);
            };
        }
    }
    return self;
}

-(void)setupUI {

    self.buttomView.layer.cornerRadius = 10;
    self.buttomView.layer.masksToBounds = YES;
    //self.themeColor = [UIColor colorFromHexRGB:@"#f7b639"];
    self.themeColor = RGB(247, 133, 51);
    self.frame=CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    
    //点击背景是否影藏
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismiss)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
    
    self.bottomConstraint.constant = -self.height;
    self.backgroundColor = RGBA(0, 0, 0, 0);
    [self layoutIfNeeded];
    
    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self];
    
    [self.showYearLabel addSubview:self.datePicker];
}

-(void)defaultConfig {
    
    if (!_scrollToDate) {
        _scrollToDate = [NSDate date]; // 默认是系统当前时间。
    }
    
    //循环滚动时需要用到
    preRow = (self.scrollToDate.year-MINYEAR)*12+self.scrollToDate.month-1;
    
    //设置年月日时分数据:rb注释:c数组初始化
    // rb 这里是创建数组对象。
    _yearArray = [self setArray:_yearArray];
    _monthArray = [self setArray:_monthArray];
    _dayArray = [self setArray:_dayArray];
    _hourArray = [self setArray:_hourArray];
    _minuteArray = [self setArray:_minuteArray];
    
    // rb 初始化 月(12个月)、小时(24小时)、分钟(60分钟)数组
    for (int i=0; i<60; i++) {
        NSString *num = [NSString stringWithFormat:@"%02d",i];
        if (0<i && i<=12)
            [_monthArray addObject:num];
        if (i<24)
            [_hourArray addObject:num];
        [_minuteArray addObject:num];
    }
    
    // rb 初始化年
    for (NSInteger i=MINYEAR; i<MAXYEAR; i++) {
        NSString *num = [NSString stringWithFormat:@"%ld",(long)i];
        [_yearArray addObject:num];
    }
    
    // 默认最大限制为2049年，最小限制为1970年
    //最大最小限制
    if (!self.maxLimitDate) {
        self.maxLimitDate = [NSDate date:@"2049-12-31 23:59" WithFormat:@"yyyy-MM-dd HH:mm"];
    }
    //最小限制
    if (!self.minLimitDate) {
        self.minLimitDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
}

// 年月日时分label
-(void)addLabelWithName:(NSArray *)nameArr {
    for (id subView in self.showYearLabel.subviews) {
        if ([subView isKindOfClass:[UILabel class]]) {
            [subView removeFromSuperview];
        }
    }
    
    for (int i=0; i<nameArr.count; i++) {
        // 可以封装一个方法:传一个frame,一个标题，返回一个label对象
        CGFloat cnt = nameArr.count;
        CGFloat w = kPickerSize.width;
        CGFloat averageW = w / cnt;
//        CGFloat labelX = kPickerSize.width/(cnt*2)+18+kPickerSize.width/cnt*i;
//        CGFloat labelX = averageW/2 + 18 + averageW * i;
//        CGFloat labelX = (averageW-18) + averageW *i;
        CGFloat labelX = (averageW-18) + averageW *i;
        // 简单的几何知识，画个图就知道了 + 18 是从左边开始算的。
        // - 18 是从右边开始算的，效果都差不多。

        CGFloat labelY = self.showYearLabel.frame.size.height/2- 8;
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(labelX, labelY, 15, 15)];
        
        label.text = nameArr[i];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = self.themeColor;
        label.backgroundColor = [UIColor clearColor];
        // 可以封装一个方法:传一个frame,一个标题，返回一个label对象
        [self.showYearLabel addSubview:label];
    }
}


// 创建可变数组对象，命名不规范。
- (NSMutableArray *)setArray:(id)mutableArray
{
    if (mutableArray) // ?
        [mutableArray removeAllObjects];
    else
        mutableArray = [NSMutableArray array];
    return mutableArray;
}

#pragma mark - UIPickerViewDelegate,UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    // 年月日时分，年月日，月日，时分。
    switch (self.datePickerStyle) {
        case DateStyleShowYearMonthDayHourMinute:
            [self addLabelWithName:@[@"年",@"月",@"日",@"时",@"分"]];
            return 5;
        case DateStyleShowYearMonthDay:
            [self addLabelWithName:@[@"年",@"月",@"日"]];
            return 3;
        case DateStyleShowMonthDayHourMinute:
            [self addLabelWithName:@[@"月",@"日",@"时",@"分"]];
            return 4;
        case DateStyleShowMonthDay:
            [self addLabelWithName:@[@"月",@"日"]];
            return 2;
        case DateStyleShowHourMinute:
            [self addLabelWithName:@[@"时",@"分"]];
            return 2;
        default:
            return 0;
    }
}

//rb 返回每个 component 的row的个数。
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {

    // 不好用语言描述，打开Excel 横：A B C D E  竖：1、2、3、4、5、6 。。。。 画图最好理解。
    NSArray *numberArr = [self getNumberOfRowsInComponent];
    
    return [numberArr[component] integerValue];
}

// rb 返回每一个component中的 row的个数
-(NSArray *)getNumberOfRowsInComponent {
    //rb 分别取出 年月日时分数组中元素的个数
    NSInteger yearNum = _yearArray.count;
    NSInteger monthNum = _monthArray.count;
    
    //rb 1-17 yearIndex赋值的地方是关键
    NSInteger dayNum = [self DaysfromYear:[_yearArray[yearIndex] integerValue] andMonth:[_monthArray[monthIndex] integerValue]];
    
    NSInteger hourNum = _hourArray.count;
    NSInteger minuteNUm = _minuteArray.count;
    
    // rb 根据不同的‘日期样式’ 返回不同的 数组
    switch (self.datePickerStyle) {
        case DateStyleShowYearMonthDayHourMinute:
            // 数组中装的是row的个数(数字)
            return @[@(yearNum),@(monthNum),@(dayNum),@(hourNum),@(minuteNUm)];
            break;
        case DateStyleShowMonthDayHourMinute:
            return @[@(monthNum),@(dayNum),@(hourNum),@(minuteNUm)];
            break;
        case DateStyleShowYearMonthDay:
            return @[@(yearNum),@(monthNum),@(dayNum)];
            break;
        case DateStyleShowMonthDay:
            return @[@(monthNum),@(dayNum),@(hourNum)];
            break;
        case DateStyleShowHourMinute:
            return @[@(hourNum),@(minuteNUm)];
            break;
        default:
            return @[];
            break;
    }
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 40;
}


// rb 返回具体的row的内容，类似tableView 的 cellForRow:
-(UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    // rb view 就是每一个component中每一个row 的内容，有点想cell ，这里讲View强制抓换为label ，就是具体的 2018- 1- 8 具体的每一个数字的label
    UILabel *customLabel = (UILabel *)view;
    if (!customLabel) {
        customLabel = [[UILabel alloc] init];
        customLabel.textAlignment = NSTextAlignmentCenter;
        [customLabel setFont:[UIFont systemFontOfSize:17]];
    }
    customLabel.backgroundColor = [UIColor clearColor];
    
    NSString *title;
    
    // rb 根据不同的日期样式返回不同 数据，
    // 比如:如果是年月日时分秒，就返回 2018-1-8 17:48 ,有五竖，从左到右分别是年、月、日、时、分
    switch (self.datePickerStyle) {
        case DateStyleShowYearMonthDayHourMinute:
            if (component==0) {
                title = _yearArray[row];
            }
            if (component==1) {
                title = _monthArray[row];
            }
            if (component==2) {
                title = _dayArray[row];
            }
            if (component==3) {
                title = _hourArray[row];
            }
            if (component==4) {
                title = _minuteArray[row];
            }
            break;
        case DateStyleShowYearMonthDay:
            if (component==0) {
                title = _yearArray[row];
            }
            if (component==1) {
                title = _monthArray[row];
            }
            if (component==2) {
                title = _dayArray[row];
            }
            break;
        case DateStyleShowMonthDayHourMinute:
            if (component==0) {
                title = _monthArray[row%12];
            }
            if (component==1) {
                title = _dayArray[row];
            }
            if (component==2) {
                title = _hourArray[row];
            }
            if (component==3) {
                title = _minuteArray[row];
            }
            break;
        case DateStyleShowMonthDay:
            if (component==0) {
                title = _monthArray[row%12];
            }
            if (component==1) {
                title = _dayArray[row];
            }
            break;
        case DateStyleShowHourMinute:
            if (component==0) {
                title = _hourArray[row];
            }
            if (component==1) {
                title = _minuteArray[row];
            }
            break;
        default:
            title = @"";
            break;
    }
    
    // rb 给每一个row 赋不同的数据。
    customLabel.text = title;
    customLabel.textColor = [UIColor blackColor];
    return customLabel;
}

// rb 第一次这个方法是不会触发，之后选择之后才会触发。点击component 的 row的方法，如果设置了最下日期,所选择的日期小于小于设置的日期，自动滚到设置的最小日期。
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // 1-17rb默认的index不应该这里进行赋值。
    // 根据不同的日期样式做不同的处理。
    switch (self.datePickerStyle) {
        case DateStyleShowYearMonthDayHourMinute:{
            if (component == 0) { // rb 这里对应的是年。
                yearIndex = row; //  rb 记录当前年份的下标
                self.showYearLabel.text =_yearArray[yearIndex]; // 这里显示底部的年份大label
            }
            if (component == 1) {
                monthIndex = row; // rb 记录月份的下标
            }
            if (component == 2) {
                dayIndex = row;
            }
            if (component == 3) {
                hourIndex = row;
            }
            if (component == 4) {
                minuteIndex = row;
            }
            
            // 有一点点明白:因为每个月的天数不一样所以要根据 year 和 month 去进行计算。
            // rb ?
            if (component == 0 || component == 1){
                [self DaysfromYear:[_yearArray[yearIndex] integerValue] andMonth:[_monthArray[monthIndex] integerValue]];
               
                // 2 - 28
                // 2 - 29
                // 4 - 30
                // 1 - 31
                
                //rb 我懂了但是不好描述 如果选择的 天的index > 最新的dayArr 
                if (_dayArray.count-1<dayIndex) {
                    dayIndex = _dayArray.count-1;
                }
            }
        }
            break;
            
        case DateStyleShowYearMonthDay:{
            
            if (component == 0) {
                yearIndex = row;
                self.showYearLabel.text =_yearArray[yearIndex];
            }
            if (component == 1) {
                monthIndex = row;
            }
            if (component == 2) {
                dayIndex = row;
            }
            if (component == 0 || component == 1){
                [self DaysfromYear:[_yearArray[yearIndex] integerValue] andMonth:[_monthArray[monthIndex] integerValue]];
                if (_dayArray.count-1<dayIndex) {
                    dayIndex = _dayArray.count-1;
                }
            }
        }
            break;
            
            
        case DateStyleShowMonthDayHourMinute:{
            if (component == 1) {
                dayIndex = row;
            }
            if (component == 2) {
                hourIndex = row;
            }
            if (component == 3) {
                minuteIndex = row;
            }
            
            if (component == 0) {
                
                [self yearChange:row];
                
                if (_dayArray.count-1<dayIndex) {
                    dayIndex = _dayArray.count-1;
                }
            }
            [self DaysfromYear:[_yearArray[yearIndex] integerValue] andMonth:[_monthArray[monthIndex] integerValue]];
            
        }
            break;
            
        case DateStyleShowMonthDay:{
            if (component == 1) {
                dayIndex = row;
            }
            if (component == 0) {
                
                [self yearChange:row];
                
                if (_dayArray.count-1<dayIndex) {
                    dayIndex = _dayArray.count-1;
                }
            }
            [self DaysfromYear:[_yearArray[yearIndex] integerValue] andMonth:[_monthArray[monthIndex] integerValue]];
        }
            break;
            
        case DateStyleShowHourMinute:{
            if (component == 0) {
                hourIndex = row;
            }
            if (component == 1) {
                minuteIndex = row;
            }
        }
            break;
            
        default:
            break;
    }
    
    [pickerView reloadAllComponents];
    
    //rb 当前选择的日期
    NSString *dateStr = [NSString stringWithFormat:@"%@-%@-%@ %@:%@",_yearArray[yearIndex],_monthArray[monthIndex],_dayArray[dayIndex],_hourArray[hourIndex],_minuteArray[minuteIndex]];
    
    //rb 滚到当前选择的日期: 将日期字符串NSString转为日期NSDate
    // 这个是set方法。点语法在等号的左边👈是set方法。
    self.scrollToDate = [[NSDate date:dateStr WithFormat:@"yyyy-MM-dd HH:mm"] dateWithFormatter:_dateFormatter];
    
    //rb 比较日期大小，和设置的最小的日期进行比较，如果是ascending：如果返回的数据小于最小日期，就自动滚到最小日期。
    //和设置的最大日期进行比较 如果是descending:如果选择的日期大于设定的最小的日期， 就滚到设置的最大的日期
    if ([self.scrollToDate compare:self.minLimitDate] == NSOrderedAscending) {
        self.scrollToDate = self.minLimitDate;
        [self getNowDate:self.minLimitDate animated:YES];
    }else if ([self.scrollToDate compare:self.maxLimitDate] == NSOrderedDescending){
        self.scrollToDate = self.maxLimitDate;
        [self getNowDate:self.maxLimitDate animated:YES];
    }
    
    _startDate = self.scrollToDate;
}

// rb 
-(void)yearChange:(NSInteger)row {
    monthIndex = row%12;
    
// rb 有点看不懂这个判断，年的下标++-- 这是要判断当前是那一年？ 判断太长 可读性差。
    if (row-preRow <12 && row-preRow>0 && [_monthArray[monthIndex] integerValue] < [_monthArray[preRow%12] integerValue]) {
        yearIndex ++;
    } else if(preRow-row <12 && preRow-row > 0 && [_monthArray[monthIndex] integerValue] > [_monthArray[preRow%12] integerValue]) {
        yearIndex --;
    }else {
        NSInteger interval = (row-preRow)/12;
        yearIndex += interval;
    }
    
    self.showYearLabel.text = _yearArray[yearIndex];
    
    preRow = row;
}


// rb 可借鉴。手势代理方法:拦截手势的执行，点击日期选择器不调用手势，点击日期选择器之外的地方调用手势，让视图消失。
#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //descendant:后代
    if( [touch.view isDescendantOfView:self.buttomView]) {
        return NO; // 点击的是日期 不调用手势
    }
    return YES; // 点击空白处 调用手势。
}



// rb 显示日期选择器。:
#pragma mark - Action
-(void)show {
    // rb 将self 添加到 keyWindow上。
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [UIView animateWithDuration:.3 animations:^{
        // rb 修改bottomConstraint约束线，这个是xib约数线，有待验证其作用。 ???
        self.bottomConstraint.constant = 100;
        self.backgroundColor = RGBA(0, 0, 0, 0.4);
        [self layoutIfNeeded];
    }];
}

// rb 影藏日期选择器
-(void)dismiss {
    [UIView animateWithDuration:.3 animations:^{
        //rb 修改xib约束线，让其等于 -屏幕高度。
        self.bottomConstraint.constant = -self.height;
        self.backgroundColor = RGBA(0, 0, 0, 0);
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        
        // rb 执行从父视图移除。
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)]; // ？？ rb 这句代码的作用？？？不懂。
        
        [self removeFromSuperview]; //rb 从父视图移除，为什么要上面的那句代码。
    }];
}

- (IBAction)doneAction:(UIButton *)btn {
//rb 有点不明白，直接将scrollToDate 传递出去不就可以了，为什么还要转换，干什么？
    // 这个还是有用的因为:有好几种样式可用。这个值_dateFormatter一直在变。
    _startDate = [self.scrollToDate dateWithFormatter:_dateFormatter];
    _startDate = self.scrollToDate; //1-17 rb 和上面的一样的。
    
    //rb 将选择的日期传递出去。
    self.doneBlock(_startDate);
    
    // rb 视图消失。
    [self dismiss];
}

// 一次不愉快的购物，快递寄了八天了，还没到。日了狗了。

#pragma mark - tools
//rb 这个方法的作用判断每个月有所少天。 通过年月求每月天数: 一三五七八十腊，三十一天永不差，二月平年29天，闰年28天
- (NSInteger)DaysfromYear:(NSInteger)year andMonth:(NSInteger)month
{
    // 传入年和月，判断这一年的这一月有多少天？
    // 年:判断是不是闰年，如果是闰年 二月就28天；如果不是闰年二月就是29天
    // 月:一三五七八十腊三十一天用不差，二月闰年29天平年28天，其他个月30天。
    NSInteger num_year  = year;
    NSInteger num_month = month;
    
    BOOL isrunNian = num_year%4==0 ? (num_year%100==0? (num_year%400==0?YES:NO):YES):NO;
    switch (num_month) {
        case 1:case 3:case 5:case 7:case 8:case 10:case 12:{ // 一三五七八十腊31天永不差。
            [self setdayArray:31];
            return 31;
        }
        case 4:case 6:case 9:case 11:{ // 4、6、9、11 每天30天
            [self setdayArray:30];
            return 30;
        }
        case 2:{
            if (isrunNian) { // 润年 2月 29天。
                [self setdayArray:29];
                return 29;
            }else{ // 平年 2月 28天
                [self setdayArray:28];
                return 28;
            }
        }
        default:
            break;
    }
    return 0;
}

//rb 设置每月的天数数组: 传入一个数,比如30,就将1----30 这30个数放入_dayArray 数组中。
- (void)setdayArray:(NSInteger)num
{
    [_dayArray removeAllObjects]; // rb 删除之前的数组中的所有元素。
    for (int i=1; i<=num; i++) {  // rb 将1---num 个数 添加到数组中。
        [_dayArray addObject:[NSString stringWithFormat:@"%02d",i]];
    }
}

#pragma mark - 关键代码。给yearIndex 变量第一次赋值的地方。
//rb 滚动到指定的时间位置 这个方法在两个地方进行了调用。
- (void)getNowDate:(NSDate *)date animated:(BOOL)animated
{
    NSLog(@"%s--%d",__FUNCTION__,__LINE__);
    
    if (!date) {
        date = [NSDate date];
    }
 
    // rb 计算当前日期对应的下标。比如:2018-1-8 13:42 ,计算对应的元素在对应的数组中的位置。
    yearIndex = date.year-MINYEAR;
    monthIndex = date.month-1;
    dayIndex = date.day-1;
    hourIndex = date.hour;
    minuteIndex = date.minute;
  
    preRow = (self.scrollToDate.year-MINYEAR)*12+self.scrollToDate.month-1;
    
    NSArray *indexArray;

    if (self.datePickerStyle == DateStyleShowYearMonthDayHourMinute)
        indexArray = @[@(yearIndex),@(monthIndex),@(dayIndex),@(hourIndex),@(minuteIndex)];
    if (self.datePickerStyle == DateStyleShowYearMonthDay)
        indexArray = @[@(yearIndex),@(monthIndex),@(dayIndex)];
    if (self.datePickerStyle == DateStyleShowMonthDayHourMinute)
        indexArray = @[@(monthIndex),@(dayIndex),@(hourIndex),@(minuteIndex)];
    if (self.datePickerStyle == DateStyleShowMonthDay)
        indexArray = @[@(monthIndex),@(dayIndex)];
    if (self.datePickerStyle == DateStyleShowHourMinute)
        indexArray = @[@(hourIndex),@(minuteIndex)];
    
    // rb 显示日期显示当前是那一年。
    self.showYearLabel.text = _yearArray[yearIndex];
    
    // rb 刷新component
    [self.datePicker reloadAllComponents];
    
    // rb 这段代码不知道用来做什么？让日期动起来。
    for (int i=0; i<indexArray.count; i++) {
        NSLog(@"i:%d-%@",i,indexArray[i]);
        
        // 数组中有几个元素，每个元素的值是对应的component的row的下标。
  /*
  @[48,0,16,18,15];
        0-48
        1-0
        2-16
        3-18
        4-15
   */
        // 滚动到对应的component的对应的row去。
        [self.datePicker selectRow:[indexArray[i] integerValue] inComponent:i animated:animated];
    }
}

#pragma mark - getter / setter
// rb 创建日期选择器对象。
-(UIPickerView *)datePicker {
    if (!_datePicker) {
        [self.showYearLabel layoutIfNeeded];
        // 和showYearLabel的bounds一样大。
        _datePicker = [[UIPickerView alloc] initWithFrame:self.showYearLabel.bounds];
        _datePicker.showsSelectionIndicator = YES;
        _datePicker.delegate = self;
        _datePicker.dataSource = self;
    }
    return _datePicker;
}

#pragma mark - yearIndex 第一次赋值的地方
- (void)rb_AssignMinLimitDate:(NSDate *)minLimitDate
{
    self.minLimitDate = minLimitDate;
    if ([_scrollToDate compare:self.minLimitDate] == NSOrderedAscending) {
        _scrollToDate = self.minLimitDate;
    }
    [self getNowDate:self.scrollToDate animated:NO];
}

-(void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.doneBtn.backgroundColor = themeColor;
}

// @property (nonatomic,assign)WSDateStyle datePickerStyle;
// set方法。
-(void)setDatePickerStyle:(WSDateStyle)datePickerStyle {
    _datePickerStyle = datePickerStyle;
    switch (datePickerStyle) {
            break;
        case DateStyleShowYearMonthDay:
        case DateStyleShowMonthDay:
            _dateFormatter = @"yyyy-MM-dd";
            break;
            
        default:
            break;
    }
    [self.datePicker reloadAllComponents];
}


#pragma mark - 感受
/**
 功能够用。
 代码是真乱呀，写的太乱，不方便别人看，也不方便后期维护。
 成员变量太多，值一直在变，不花点时间，根本找不到第一次赋值是在哪里进行的。
 先把别人的代码看懂，然后仿一遍，之后优化代码逻辑，方法起名字原则：看到方法名就知道是要干什么，长不要紧，要紧的是要看的懂。
 优化逻辑。
 
 看的想吐啊。变来变去，醉了呀，我要重构。还是看的一知半解，这时候就要较真了，按一个星期看，一点一点调试，非给你弄透不可，代码还是要自己写一遍才可以呀。有易到难。
 */

#pragma mark - 代码说明（一）
/**
 MB 代码写的好乱呀。名字胡鸡巴起。看的痛苦啊啊啊啊啊啊啊啊啊啊啊。五号开始写，今天11 好还没搞定，看的很痛苦。
 yearIndex 在好多方法里面进行赋值
 第一次赋值的地方。在minLimitDate的set方法里面进行的，但是还有一个条件就是 _scrollToDate 默认是系统当前时间.
 */

/**1-17 又看了半天一个感觉还是乱:名字随便起，一个变量反复赋值，操你大爷的，看半天都看不懂，
 在看一会看懂了哥就自己写写一个好看的好用的。自己提需求自己实现。恩滴骄傲从何而来是你过硬的技术还是什么一共就5千块钱还扣，人就跌长记性，苦练技术，才有选择的资本，我只是想拥有做还是不做的选择。最好是开除，不然还的我写申请，走的时候，我该一个字节的东西。同时打包一下静态库，自己写的东西你们自能看不能改。你们可以选择扣我钱，我可以选择:一个有一个小bug的代码，然后打包成静态库。
 */
@end
