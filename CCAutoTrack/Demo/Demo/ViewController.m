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
    [btn setTitle:@"按钮" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UISwitch *swi = [[UISwitch alloc] initWithFrame:CGRectMake(100, 170, 80, 50)];
    [swi addTarget:self action:@selector(switchAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:swi];
    
    UISlider *sli = [[UISlider alloc] initWithFrame:CGRectMake(100, 200, 200, 50)];
    [sli addTarget:self action:@selector(sliderAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sli];
    
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"左边", @"右边"]];
    seg.frame = CGRectMake(100, 250, 80, 50);
    [seg addTarget:self action:@selector(segementedControlAction) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:seg];
    
    UIStepper *step = [[UIStepper alloc] initWithFrame:CGRectMake(100, 320, 80, 50)];
    [step addTarget:self action:@selector(stepperAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:step];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 360, 220, 50)];
    label.text = @"我是一个Label";
    label.userInteractionEnabled = YES;
    [self.view addSubview:label];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLabelAction)];
    [label addGestureRecognizer:tap];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressLabelAction)];
    [label addGestureRecognizer:longPress];
    
    UIButton *btnStart = [[UIButton alloc] initWithFrame:CGRectMake(30, 420, 50, 50)];
    btnStart.backgroundColor = [UIColor redColor];
    [btnStart setTitle:@"开始" forState:UIControlStateNormal];
    [btnStart addTarget:self action:@selector(timerStartAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnStart];
    
    UIButton *btnPause = [[UIButton alloc] initWithFrame:CGRectMake(90, 420, 50, 50)];
    btnPause.backgroundColor = [UIColor redColor];
    [btnPause setTitle:@"暂停" forState:UIControlStateNormal];
    [btnPause addTarget:self action:@selector(timerPauseAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnPause];
    
    UIButton *btnResume = [[UIButton alloc] initWithFrame:CGRectMake(150, 420, 50, 50)];
    btnResume.backgroundColor = [UIColor redColor];
    [btnResume setTitle:@"继续" forState:UIControlStateNormal];
    [btnResume addTarget:self action:@selector(timerResumeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnResume];
    
    UIButton *btnEnd = [[UIButton alloc] initWithFrame:CGRectMake(210, 420, 50, 50)];
    btnEnd.backgroundColor = [UIColor redColor];
    [btnEnd setTitle:@"结束" forState:UIControlStateNormal];
    [btnEnd addTarget:self action:@selector(timerEndAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnEnd];
    
    UIButton *btnTableView = [[UIButton alloc] initWithFrame:CGRectMake(30, 490, 130, 50)];
    btnTableView.backgroundColor = [UIColor redColor];
    [btnTableView setTitle:@"TableView" forState:UIControlStateNormal];
    [btnTableView addTarget:self action:@selector(tableViewAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnTableView];
    
    UIButton *btnCollectionView = [[UIButton alloc] initWithFrame:CGRectMake(180, 490, 130, 50)];
    btnCollectionView.backgroundColor = [UIColor redColor];
    [btnCollectionView setTitle:@"CollectionView" forState:UIControlStateNormal];
    [btnCollectionView addTarget:self action:@selector(collectionViewAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnCollectionView];
    
    UIButton *btnException = [[UIButton alloc] initWithFrame:CGRectMake(30, 550, 130, 50)];
    btnException.backgroundColor = [UIColor redColor];
    [btnException setTitle:@"Exception" forState:UIControlStateNormal];
    [btnException addTarget:self action:@selector(exceptionCrash) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnException];
    
    UIButton *btnSignal = [[UIButton alloc] initWithFrame:CGRectMake(180, 550, 130, 50)];
    btnSignal.backgroundColor = [UIColor redColor];
    [btnSignal setTitle:@"CollectionView" forState:UIControlStateNormal];
    [btnSignal addTarget:self action:@selector(signalCrash) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnSignal];
}

#pragma mark - test for viewScreen

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear");
}

#pragma mark - test for click

- (void)onBtnClick:(UIButton *)sender {
    NSLog(@"按钮被点击");
}

- (void)switchAction {
    NSLog(@"开关被点击");
}

- (void)sliderAction {
    NSLog(@"滑条被点击");
}

- (void)segementedControlAction {
    NSLog(@"切换条被点击");
}

- (void)stepperAction {
    NSLog(@"计步器被点击");
}

#pragma mark - test for gesture

- (void)tapLabelAction {
    NSLog(@"tap label gesture");
}

- (void)longPressLabelAction {
    NSLog(@"long press label gesture");
}

#pragma mark - test for UITableView/UICollectionView

- (void)tableViewAction {
    TableViewController *vc = [[TableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)collectionViewAction {
    CollectionViewController *vc = [[CollectionViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - test for timer

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

#pragma mark - test for exception

- (void)exceptionCrash {
    NSArray *names = @[@"Tom", @"Jack"];
    NSLog(@"%@", names[2]);
}

- (void)signalCrash {
    CCAutoTrackReleaseObject *releaseObj = [[CCAutoTrackReleaseObject alloc] init];
    [releaseObj signalCrash];
}

@end
