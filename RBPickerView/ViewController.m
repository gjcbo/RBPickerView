//
//  ViewController.m
//  RBPickerView
//
//  Created by RaoBo on 2018/1/18.
//  Copyright © 2018年 RaoBo. All rights reserved.
//

#import "ViewController.h"
#import "RBDatePickerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)selectDateAction:(UIButton *)sender {
    
    [self rbDatePickerViewDemo];
}
- (void)rbDatePickerViewDemo
{
    RBDatePickerView *datePV = [[RBDatePickerView alloc] initWithCompleteBlock:^(NSDate *selectedDate) {
        
    }];
    
    [datePV rb_AssignMinLimitDate:[NSDate date]];
    [datePV rb_show];
}


@end
