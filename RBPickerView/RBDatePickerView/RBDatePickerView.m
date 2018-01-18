//
//  RBDatePickerView.m
//  RBDatePickerView
//
//  Created by RaoBo on 2018/1/5.
//  Copyright © 2018年 RaoBo. All rights reserved.
//

#import "RBDatePickerView.h"
#import "NSDate+Extension.h"

#define kScreen_W [UIScreen mainScreen].bounds.size.width
#define kScreen_H [UIScreen mainScreen].bounds.size.height

#define kMinimumYear 1970
#define kMaximumYear 2049
#define RGBA(r, g, b, a) ([UIColor colorWithRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:a])
#define RGB(r, g, b) RGBA(r,g,b,1)


@interface RBDatePickerView ()<UIPickerViewDelegate,UIPickerViewDataSource,UIGestureRecognizerDelegate>

//一 :记录下标:记录当前选中的是哪一个component的哪一个row
{
    NSInteger _yearIndex;
    NSInteger _monthIndex;
    NSInteger _dayIndex;
    NSInteger _hourIndex;
    NSInteger _minuteIndex;
}

// 数据源数组 ：年、月、日、时、分数组
@property(nonatomic, strong) NSMutableArray *yearArr;
@property(nonatomic, strong) NSMutableArray *monthArr;
@property(nonatomic, strong) NSMutableArray *dayArr;
@property(nonatomic, strong) NSMutableArray *hourArr;
@property(nonatomic, strong) NSMutableArray *minuteArr;

// 二: UI
/**1.底部背景图片 添加到self上*/
@property(nonatomic, strong) UIView *bottomView;
/**2.显示年份的大label 添加到 bottomView 上*/
@property(nonatomic, strong) UILabel *showYearLabel;
/**3.日期选择器 添加到showYearLabel 上*/
@property(nonatomic, strong) UIPickerView *dateView;
/**4.确定按钮 添加到 bottomView 上*/
@property(nonatomic, strong) UIButton *sureBtn;

// 三: 工具变量。
/**5. 最终选择的日期 应该有一个默认值*/
@property(nonatomic, strong) NSDate *finalSelectedDate;
/**6.日期格式对象*/
@property(nonatomic, strong) NSString *dateFmtStr;

// 四: 默认最大最下日期，.h 中提供两个接口方法设置这两个变量的值。不想外界直接访问，不想重写set方法进行赋值。
/**7.最大日期限制*/
@property(nonatomic, strong) NSDate *maxLimitDate;
/**8.最小日期限制*/
@property(nonatomic, strong) NSDate *minLimitDate;
@end

@implementation RBDatePickerView
#pragma mark - 一 lazy 数据源
- (NSMutableArray *)yearArr{
    if (!_yearArr) {
        _yearArr = [NSMutableArray array];
    }
    return _yearArr;
}

- (NSMutableArray *)monthArr{
    if (!_monthArr) {
        _monthArr = [NSMutableArray array];
    }
    return _monthArr;
}

- (NSMutableArray *)dayArr{
    if (!_dayArr) {
        _dayArr = [NSMutableArray array];
    }
    return _dayArr;
}

- (NSMutableArray *)hourArr{
    if (!_hourArr) {
        _hourArr = [NSMutableArray array];
    }
    return _hourArr;
}

- (NSMutableArray *)minuteArr{
    if (!_minuteArr) {
        _minuteArr = [NSMutableArray array];
    }
    return _minuteArr;
}


#pragma mark - 二 init初始化
- (instancetype)initWithCompleteBlock:(CompleteBlock)compBlock
{
    self = [super init];
    
    if (self) {
        [self createUI];
        [self defaultConfig];
    }
    return self;
}

- (void)createUI{
    self.frame = CGRectMake(0, 0, kScreen_W, kScreen_H);
    self.backgroundColor = RGBA(142, 142, 142, 0.7);
    
    CGFloat bottomView_H = 300;
    CGFloat bottomView_W = kScreen_W - 20;
    // 底部view
    self.bottomView.frame = CGRectMake(10, kScreen_H,bottomView_W , bottomView_H);// frame:左右间距10 高度200  y轴一个屏幕高度
    [self addSubview:self.bottomView];
    
    CGFloat showYearLabel_H = 250;
    self.showYearLabel.frame = CGRectMake(0, 0, bottomView_W, showYearLabel_H);
    [self.bottomView addSubview:self.showYearLabel];
    
    // 将日期选择器添加到self.showYearLabel上
    self.dateView.frame = self.showYearLabel.bounds;
    [self.showYearLabel addSubview:self.dateView];
    
    self.sureBtn.frame = CGRectMake(0,showYearLabel_H , bottomView_W,bottomView_H - showYearLabel_H);
    [self.bottomView addSubview:self.sureBtn];
    
    // 给self 添加手势
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesActiom:)];
    tapGes.delegate = self; // 设置手势代理
    [self addGestureRecognizer:tapGes];
}

/* 初始化年月日时分数据源数组。
  年数固定: 1970---2049
  月数固定:12个月
  每月天数不固定:28，29，30，31天不等。
  每天小时数固定：24小时
  每小时分钟数固定:60分钟
 **/

- (void)defaultConfig
{
    // 年
    for (int i=kMinimumYear; i<=kMaximumYear; i++) {
        NSString *yearStr = [NSString stringWithFormat:@"%d",i];
        [self.yearArr addObject:yearStr];
    }
    
    for (int j=0; j<60; j++) {
        if (j<12) {//每年12个月 1-12 ✅
            [self.monthArr addObject:[NSString stringWithFormat:@"%d",j+1]];
        }
        
        if (j<24) {// 每天24小时 注意:00-23 ✅   01-24❌会奔溃的。
            [self.hourArr addObject:[NSString stringWithFormat:@"%02d",j]];
        }
        // 每小时60分钟 00-59✅   1-60❌崩溃
        [self.minuteArr addObject:[NSString stringWithFormat:@"%02d",j]];
    }
    
    // 默认最大最小值
    if (!self.maxLimitDate) {
        self.maxLimitDate = [NSDate date:@"2049-12-13 23:59" WithFormat:@"yyyy-MM-dd HH:mm" ];
    }
}

- (BOOL)isRunNianWithYear:(NSInteger)year
{
    if ((year %4==0) && (year %100!=0)) {return YES;}
    
    if (year % 400 ==0) {return YES;}

    return NO;
}

- (void)tapGesActiom:(UITapGestureRecognizer *)tapGes
{
    [self dismiss];
}

#pragma mark - 三 UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    // descendant:子孙、后代。
    // isDescendantOfView 判断一个View是不是另一个View的子类。
    if ([touch.view isDescendantOfView:self.bottomView]) {
        return NO;
    }
    return YES;
}

- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.layer.masksToBounds = YES;
        _bottomView.layer.cornerRadius = 5;
        _bottomView.backgroundColor = [UIColor whiteColor];
    }
    return _bottomView;
}
// 懒加载控件。
- (UILabel *)showYearLabel{
    if (!_showYearLabel) {
        _showYearLabel = [[UILabel alloc] init];
        _showYearLabel.font = [UIFont systemFontOfSize:110];
        _showYearLabel.textColor = RGBA(170, 170, 170, 0.7);
        _showYearLabel.textAlignment = NSTextAlignmentCenter;
        _showYearLabel.text = @"2018";
        // 坑了一下午。pickerView是添加在showYearLabel上的。默认UILabel、UIImageView的交互是不可用的。所以怎么点都没反应。 记得打开交互。
        _showYearLabel.userInteractionEnabled = YES;
    }
    return _showYearLabel;
}

- (UIButton *)sureBtn{
    if (!_sureBtn) {
        _sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sureBtn setTitle:@"确定" forState:(UIControlStateNormal)];
        [_sureBtn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [_sureBtn setTitleColor:[UIColor lightGrayColor] forState:(UIControlStateHighlighted)];
        _sureBtn.titleLabel.font = [UIFont systemFontOfSize:20.0];
        _sureBtn.backgroundColor = RGB(59, 162, 255);
        [_sureBtn addTarget:self action:@selector(clickSureBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _sureBtn;
}


/**创建日期选择器控件*/
- (UIPickerView *)dateView{
    if (!_dateView) {
        _dateView = [[UIPickerView alloc] init];
        _dateView.delegate = self;
        _dateView.dataSource = self;
        _dateView.showsSelectionIndicator = YES;
    }
    return _dateView;
}

- (void)clickSureBtnAction:(UIButton *)btn
{
    NSLog(@"点击了确定按钮");
    [self dismiss];
}

#pragma mark - 四 UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    NSArray *nameArr = @[@"年",@"月",@"日",@"时",@"分"];
    [self addYearMonthDayEtcLabelWithNameArr:nameArr];
    
    return 5;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    NSArray *tempArr = [self countingRowsOfEachComponent];
   
    return [tempArr[component] integerValue];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *customLabel = [[UILabel alloc] init];
    customLabel.textAlignment = NSTextAlignmentCenter;
    
    NSString *titleStr = nil;
    if (component == 0) {
        titleStr = self.yearArr[row];
    }else if (component == 1){
        titleStr = self.monthArr[row];
    }else if (component == 2){
//        NSLog(@"%s-%d行-:%ld",__FUNCTION__,__LINE__,self.dayArr.count);
        
        titleStr = self.dayArr[row];
    }else if (component == 3){
        titleStr = self.hourArr[row];
    }else{
        titleStr = self.minuteArr[row];
    }
    customLabel.text = titleStr;
    return customLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if (component == 0) { // 年
//        NSString *yearStr = self.yearArr[row];
        _yearIndex = row; // 重新记录下标
        // 个人觉得更新year数据的时机不合适。
//        [self rb_updateShowYearLabelTitle:yearStr];
    }
    
    if (component == 1) {
        _monthIndex = row;
    }
    
    if (component == 3) {
        _hourIndex = row;
    }
    
    if (component == 4) {
        _minuteIndex = row;
    }
    
    // 记录day下标
    if (component == 2) {
        _dayIndex = row;
    }
    
    // 根据所选year和month重新计算day的天数
    if ((component == 0) || (component==1)) { // 日 根据year 和 month 进行计算所得。
        NSInteger yInt = [self.yearArr[_yearIndex] intValue];
        NSInteger mInt = [self.monthArr[_monthIndex] intValue];
        
        // 根据选中的日期 重新给self.dayArray 数组赋值。
        [self assignDayArrWithYear:yInt month:mInt];
    
        // 这里处理这样一种情况:2月可能为28、29 其他各月可能为30、31, eg:1-31 改为2-31肯定有问题，所以如果算出来的数组的总元素个数 小于 所选 _dayIndex，说明是该月的最后一天 2-28(平年)、2-19(闰年)此时需要重新计算_dayIndex
        if (self.dayArr.count < _dayIndex) {
            _dayIndex = self.dayArr.count - 1;
        }
    }
    
    [self.dateView reloadAllComponents]; // 1-18 ⚠️ 一定要刷新。
    
    // 选择的日期是
    NSString *selectDateStr = [self convertSelectRowsContentToDateStr];
    NSDate *selectedDate = [NSDate date:selectDateStr WithFormat:@"yyyy-MM-dd HH:mm"];
    
    NSLog(@"选中的日期是:%@",selectedDate);
    
    if ([selectedDate compare:self.minLimitDate] == NSOrderedAscending) {
        [self rb_scrollToDate:self.minLimitDate];
    }else{
        [self rb_scrollToDate:selectedDate];
    }
}

- (NSString *)convertSelectRowsContentToDateStr
{
    NSLog(@"年:%@ %@ %@ %@ %@",self.yearArr[_yearIndex],self.monthArr[_monthIndex],self.dayArr[_dayIndex],self.hourArr[_hourIndex],self.minuteArr[_minuteIndex]);
    
    NSString *yStr = [NSString stringWithFormat:@"%@",self.yearArr[_yearIndex]];
    NSString *mStr = [NSString stringWithFormat:@"%@",self.monthArr[_monthIndex]];
    NSString *dStr = [NSString stringWithFormat:@"%@",self.dayArr[_dayIndex]];
    NSString *hStr = [NSString stringWithFormat:@"%@",self.hourArr[_hourIndex]];
    NSString *mmStr = [NSString stringWithFormat:@"%@",self.minuteArr[_minuteIndex]];
    NSString *ymdhmStr = [NSString stringWithFormat:@"%@-%@-%@ %@:%@",yStr,mStr,dStr,hStr,mmStr];
    NSLog(@"ymdhmStr:%@",ymdhmStr);
    
    return ymdhmStr;
}

#pragma mark - 五 工具方法
/**1. 返回一个label */
- (UILabel *)createALabelWithFrame:(CGRect)frame title:(NSString *)title
{
    UILabel *aaaLabel = [[UILabel alloc] initWithFrame:frame];
    aaaLabel.text = title;
    aaaLabel.textColor = [UIColor brownColor];
    aaaLabel.font = [UIFont systemFontOfSize:17.0];
    aaaLabel.backgroundColor = [UIColor clearColor];
    
    return aaaLabel;
}

/**2. */
- (void)addYearMonthDayEtcLabelWithNameArr:(NSArray *)nameArr
{
    NSInteger cnt = nameArr.count;

    // 上面默认: self.dateVeiw.bounds = self.showYearLabel.bounds
    CGFloat averageW = self.dateView.bounds.size.width / cnt; // 等分dateView的宽
    CGFloat label_WH = 15;
    CGFloat label_y = (self.dateView.bounds.size.height - label_WH) / 2;
    
    for (int i= 0; i<cnt; i++) {
        CGFloat label_x = (averageW-18) + (averageW *i); // 简单的知识，画图就明了。我使用是减法(平均宽度-18 就是第一个label的x轴坐标，每次都加上一个平均宽度)
        CGRect tipsLbFrame = CGRectMake(label_x, label_y, label_WH, label_WH);
        UILabel *tipsLb = [self createALabelWithFrame:tipsLbFrame title:nameArr[i]];
        
        [self.showYearLabel addSubview:tipsLb];
    }
}

/**3. 传入year和 month 判断该年的该月有多少天*/
- (NSInteger)daysWithYear:(NSInteger)year month:(NSInteger)month
{
    // 一三五七八十腊，三十一天永不差。平年二月28天、闰年29天，其他各月30天
    switch (month) {
        case 1: case 3: case 5: case 8: case 10: case 12:
        {return 31;}
            break;
            
        case 4: case 6: case 7: case 9: case 11:
        {return 30;}
            break;
            
        case 2:{
            if ([self isRunNianWithYear:year]) {
                return 29;
            }else{
                return 28;
            }
        }
            break;
            
        default:{return 0;}
            break;
    }
}

/**3.2 给dayArray数组赋值*/
- (void)assignDayArrWithYear:(NSInteger)year month:(NSInteger)month
{
    NSInteger dayCount = [self daysWithYear:year month:month];
    
    // 清空之前的数据,不然有bug
    [self.dayArr removeAllObjects];
    
    for (int i=1; i<=dayCount; i++) { // 日期从1号开始 ----28、29、30、31不等
        NSString *whichDayStr = [NSString stringWithFormat:@"%d",i];
        
        [self.dayArr addObject:whichDayStr];
    }
}

/**4.1-17 计算每一个component 对应的row的个数 */
- (NSArray *)countingRowsOfEachComponent
{
    // 年月日时分
    NSInteger yearCnt = self.yearArr.count;
    NSInteger monthCnt = self.monthArr.count;
    NSInteger hourCnt = self.hourArr.count;
    NSInteger minuteCnt = self.minuteArr.count; // 对号入座。心真大呀。
    
    //1-17 rb 如何知道是那一年的那一月 _yearIndex 在setMinLimitDate这里首次赋值
    NSInteger y = [self.yearArr[_yearIndex] intValue];
    NSInteger m = [self.monthArr[_monthIndex] intValue];
    NSInteger dayCnt = [self daysWithYear:y month:m];
    
    NSString *yStr = [NSString stringWithFormat:@"%ld",(long)yearCnt];
    NSString *mStr = [NSString stringWithFormat:@"%ld",(long)monthCnt];
    NSString *dStr = [NSString stringWithFormat:@"%ld",(long)dayCnt];
    NSString *hStr = [NSString stringWithFormat:@"%ld",(long)hourCnt];
    NSString *mmStr = [NSString stringWithFormat:@"%ld",(long)minuteCnt];
    
    NSArray *tempArr = @[yStr,mStr,dStr,hStr,mmStr];
    return tempArr;
}



/**5. 滚到指定的日期
 默认初始 _yearIndex 等下标的初始化位置
 */
- (void)rb_scrollToDate:(NSDate *)aDate
{
//    NSLog(@"%ld %ld %ld %ld %ld",aDate.year,aDate.month,aDate.day,aDate.hour,aDate.minute);
    
    NSInteger y = aDate.year;
    NSInteger m = aDate.month;
    NSInteger d = aDate.day;
    NSInteger h = aDate.hour;
    NSInteger mm = aDate.minute;
    NSLog(@"当前日期:%ld %ld %ld %ld %ld",y,m,d,h,mm); // eg:当前日期2018 1 17 19 42
    
    //给self.dayArray赋值 因为每个月的天数都不一样需要传入 year 和 month 去进行计算
    [self assignDayArrWithYear:y month:m];
    
    // 计算index  给index赋值
    _yearIndex = y-kMinimumYear;
    _monthIndex = m-1; // 1-12
    _dayIndex = d-1;   // 1-31
    _hourIndex = h;    // 00-23
    _minuteIndex = mm; // 00-59

    // 应该在这里更新showYearLabel的内容
    NSString *selectYearStr = [NSString stringWithFormat:@"%@",self.yearArr[_yearIndex]];
    [self rb_updateShowYearLabelTitle:selectYearStr];
    
    NSArray *rowsOfComponentArr = @[@(_yearIndex),@(_monthIndex),@(_dayIndex),@(_hourIndex),@(_minuteIndex)];
    
    // ❗️滚动
    for (int j=0; j<rowsOfComponentArr.count; j++) {
        NSInteger rowsOfComponent = [rowsOfComponentArr[j] integerValue];
        [self.dateView selectRow:rowsOfComponent inComponent:j animated:YES];
    }
}

/**6. 更新showYearLabel文字*/
- (void)rb_updateShowYearLabelTitle:(NSString *)title
{
    self.showYearLabel.text = title;
}

#pragma mark - 六 show & dismiss
- (void)rb_show{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];
    
    [UIView animateWithDuration:0.3 animations:^{
        // 修改self.bottom的frame实现动画效果
        CGRect bottomViewFrame = self.bottomView.frame;
        bottomViewFrame.origin.y = kScreen_H - 300-25;
        self.bottomView.frame = bottomViewFrame;
        // 羡慕嫉妒恨啊，你们都🐂b，我还是菜藕。
    }];
}

- (void)dismiss
{
    [self removeFromSuperview];
}

#pragma mark 七
- (void)rb_AssignMinLimitDate:(NSDate *)minDate{
    _minLimitDate = minDate;
    
    //❌ ？ 如果外面不调用这个方法你怎么办。？
    [self rb_scrollToDate:minDate];
}



#pragma mark - 感叹
//不容易呀，干什么都不容易，不容易是因为你做的少的，会的少了，代码敲少了。
// 什么时候感觉so easy ，妈妈再也不不用担心我的学习。 把难的搞定，搞透彻就容易了。

@end
