//
//  CCAutoTrackExceptionHandler.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/8/3.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackExceptionHandler.h"
#import "CCAutoTrackSDK.h"

static NSString * const CCAutoTrackSignalExceptionHandlerName = @"SignalExceptionHandler";
static NSString * const CCAutoTrackSignalExceptionHandlerUserInfo = @"SignalExceptionHandlerUserInfo";

@interface CCAutoTrackExceptionHandler ()

@property (nonatomic) NSUncaughtExceptionHandler *previousExceptionHandler;

@end

@implementation CCAutoTrackExceptionHandler

+ (instancetype)sharedInstance {
    static CCAutoTrackExceptionHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CCAutoTrackExceptionHandler alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _previousExceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(&cc_uncaught_exception_handler);
        
        // 定义信号集结构体
        struct sigaction sig;
        // 将信号集初始化为空
        sigemptyset(&sig.sa_mask);
        // 处理函数中传入的__siginfo参数
        sig.sa_flags = SA_SIGINFO;
        // 设置信号集处理函数
        sig.sa_sigaction = &cc_signal_exception_handler;
        // 定义需要采集的信号类型
        int signals[] = {SIGILL, SIGABRT, SIGBUS, SIGFPE, SIGSEGV};
        for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
            // 注册信号处理
            int err = sigaction(signals[i], &sig, NULL);
            if (err) {
                NSLog(@"Errored while trying to set up sigaction for signal %d", signals[i]);
            }
        }
    }
    return self;
}

static void cc_uncaught_exception_handler(NSException *exception) {
    // 采集$AppCrashed事件
    [[CCAutoTrackExceptionHandler sharedInstance] trackAppCrashedWithException:exception];
    
    // 获取并传递UncaughtExceptionHandler
    NSUncaughtExceptionHandler *handler = [CCAutoTrackExceptionHandler sharedInstance].previousExceptionHandler;
    if (handler) {
        handler(exception);
    }
}

static void cc_signal_exception_handler(int sig, struct __siginfo *info, void *context) {
    // 创建一个异常对象，用于采集异常信息
    NSDictionary *userInfo = @{CCAutoTrackSignalExceptionHandlerUserInfo : @(sig)};
    NSString *reason = [NSString stringWithFormat:@"Signal %d was raised.", sig];
    NSException *exception = [NSException exceptionWithName:CCAutoTrackSignalExceptionHandlerName reason:reason userInfo:userInfo];
    
    // 采集$AppCrashed事件
    [[CCAutoTrackExceptionHandler sharedInstance] trackAppCrashedWithException:exception];
}

- (void)trackAppCrashedWithException:(NSException *)exception {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 异常名称
    NSString *name = [exception name];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常的堆栈信息
    NSArray *stacks = [exception callStackSymbols] ?: [NSThread callStackSymbols];
    // 将异常信息组装
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception name: %@\nException reason: %@\nException stacks: %@", name, reason, stacks];
    // 设置$AppCrashed的事件属性
    properties[@"$app_crashed_reason"] = exceptionInfo;
    
    [[CCAutoTrackSDK sharedInstance] track:@"$AppCrashed" properties:properties];
    
    // 采集$AppEnd回调block
    dispatch_block_t trackAppEndBlock = ^{
        // 判断应用是否处于运行状态
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [[CCAutoTrackSDK sharedInstance] track:@"$AppEnd" properties:nil];
        }
    };
    
    // 获取主线程
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // 判断当前线程是否为主线程
    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(mainQueue)) == 0) {
        // 如果当前是主线程，直接调用block
        trackAppEndBlock();
    } else {
        // 如果当前不是主线程，同步调用block
        dispatch_sync(mainQueue, trackAppEndBlock);
    }
    
    // 获取CCAutoTrackSDK中的serialQueue
    dispatch_queue_t serialQueue = [[CCAutoTrackSDK sharedInstance] valueForKeyPath:@"serialQueue"];
    // 阻塞当前线程，让serialQueue执行完成
    dispatch_sync(serialQueue, ^{});
    
    // 获取数据存储时的线程
    dispatch_queue_t databaseQueue = [[CCAutoTrackSDK sharedInstance] valueForKeyPath:@"database.queue"];
    // 阻塞当前线程，让$AppCrashed事件先入库
    dispatch_sync(databaseQueue, ^{});
    
    NSSetUncaughtExceptionHandler(NULL);
    
    int signals[] = {SIGILL, SIGABRT, SIGBUS, SIGFPE, SIGSEGV};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
        signal(signals[i], SIG_DFL);
    }
}

@end
