//
//  ViewController.m
//  Demo
//
//  Created by 周日朝 on 2020/7/28.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "ViewController.h"
#import "TableViewController.h"
#import "CollectionViewController.h"
#import "CCAutoTrackReleaseObject.h"
#import <CCAutoTrack/CCAutoTrack.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"首页";
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 50, 50)];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"我是按钮" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UISwitch *swi = [[UISwitch alloc] initWithFrame:CGRectMake(100, 170, 80, 50)];
    [swi addTarget:self action:@selector(switchAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:swi];
    
    UISlider *sli = [[UISlider alloc] initWithFrame:CGRectMake(100, 220, 200, 50)];
    [sli addTarget:self action:@selector(sliderAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sli];
    
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"左边", @"右边"]];
    seg.frame = CGRectMake(100, 260, 80, 50);
    [seg addTarget:self action:@selector(segementedControlAction) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:seg];
    
    UIStepper *step = [[UIStepper alloc] initWithFrame:CGRectMake(100, 320, 80, 50)];
    [step addTarget:self action:@selector(stepperAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:step];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 380, 80, 50)];
    label.text = @"我是一个Label";
    label.userInteractionEnabled = YES;
    [self.view addSubview:label];
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLabelAction)];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressLabelAction)];
    [label addGestureRecognizer:longPress];
    
    UIButton *btnStart = [[UIButton alloc] initWithFrame:CGRectMake(20, 440, 50, 50)];
    btnStart.backgroundColor = [UIColor redColor];
    [btnStart setTitle:@"开始" forState:UIControlStateNormal];
    [btnStart addTarget:self action:@selector(timerStartAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnStart];
    
    UIButton *btnPause = [[UIButton alloc] initWithFrame:CGRectMake(80, 440, 50, 50)];
    btnPause.backgroundColor = [UIColor redColor];
    [btnPause setTitle:@"暂停" forState:UIControlStateNormal];
    [btnPause addTarget:self action:@selector(timerPauseAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnPause];
    
    UIButton *btnResume = [[UIButton alloc] initWithFrame:CGRectMake(140, 440, 50, 50)];
    btnResume.backgroundColor = [UIColor redColor];
    [btnResume setTitle:@"继续" forState:UIControlStateNormal];
    [btnResume addTarget:self action:@selector(timerResumeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnResume];
    
    UIButton *btnEnd = [[UIButton alloc] initWithFrame:CGRectMake(200, 440, 50, 50)];
    btnEnd.backgroundColor = [UIColor redColor];
    [btnEnd setTitle:@"结束" forState:UIControlStateNormal];
    [btnEnd addTarget:self action:@selector(timerEndAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnEnd];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear");
}

- (void)onBtnClick:(UIButton *)sender {
    NSLog(@"按钮被点击");
    TableViewController *vc = [[TableViewController alloc] init];
//    CollectionViewController *vc = [[CollectionViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    
//    NSArray *names = @[@"Tom", @"Jack"];
//    NSLog(@"%@", names[2]);
    
//    CCAutoTrackReleaseObject *releaseObj = [[CCAutoTrackReleaseObject alloc] init];
//    [releaseObj signalCrash];
}

- (void)switchAction {
    NSLog(@"开关");
}

- (void)sliderAction {
    NSLog(@"滑条");
}

- (void)segementedControlAction {
    NSLog(@"切换");
}

- (void)stepperAction {
    NSLog(@"我也不知道这是什么");
}

- (void)tapLabelAction {
    NSLog(@"tap label gesture");
}

- (void)longPressLabelAction {
    NSLog(@"long press label gesture");
}

- (void)timerStartAction {
    [[CCAutoTrackSDK sharedInstance] trackTimerStart:@"DoSomething"];
}

- (void)timerPauseAction {
    [[CCAutoTrackSDK sharedInstance] trackTimerPause:@"DoSomething"];
}

- (void)timerResumeAction {
    [[CCAutoTrackSDK sharedInstance] trackTimerResume:@"DoSomething"];
}

- (void)timerEndAction {
    [[CCAutoTrackSDK sharedInstance] trackTimerEnd:@"DoSomething" properties:nil];
}

@end
