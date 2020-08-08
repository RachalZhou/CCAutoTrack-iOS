//
//  CCAutoTrackSDK.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/7/28.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackSDK.h"
#include <sys/sysctl.h>
#import "UIView+CCAutoTrack.h"
#import "CCAutoTrackKeychainItem.h"
#import "CCAutoTrackFileStore.h"
#import "CCAutoTrackDatabase.h"
#import "CCAutoTrackNetwork.h"
#import "CCAutoTrackExceptionHandler.h"

static NSString * const CCAutoTrackVersion = @"1.0.0";

static NSString * const CCAutoTrackEventIsPauseKey = @"is_pause";
static NSString * const CCAutoTrackEventBeginKey = @"event_begin";
static NSString * const CCAutoTrackEventDurationKey = @"event_duration";
static NSString * const CCAutoTrackEventDidEnterBackgroundKey = @"did_enter_background";

static NSString * const CCAutoTrackLoginId = @"cn.cc.login_id";
static NSString * const CCAutoTrackAnonymousId = @"cn.cc.anonymous_id";
static NSString * const CCAutoTrackKeychainService = @"cn.cc.CCAutoTrack.id";

static NSUInteger const CCAutoTrackDefaultFlushEventCount = 50;

@interface CCAutoTrackSDK ()

/// SDK默认自动采集的事件属性即预置属性
@property (nonatomic, copy) NSDictionary<NSString *, id> *automaticProperties;

/// 标记应用程序是否已收到UIApplicationWillResignActiveNotification本地通知
@property (nonatomic) BOOL applicationWillResignActive;

/// 是否为被动启动
@property (nonatomic, getter=isLaunchedPassively) BOOL launchedPassively;

/// 登录ID
@property (nonatomic, copy) NSString *loginId;

/// 事件开始发生的时间戳
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *trackTimer;

/// 保存进入后台时未暂停事件名称
@property (nonatomic, strong) NSMutableArray<NSString *> *enterBackgroundTrackTimerEvents;

/// 文件存储对象
@property (nonatomic, strong) CCAutoTrackFileStore *fileStore;

/// 数据库存储对象
@property (nonatomic, strong) CCAutoTrackDatabase *database;

/// 发送网络请求的对象
@property (nonatomic, strong) CCAutoTrackNetwork *network;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@property (nonatomic, strong) NSTimer *flushTimer;

@end

@implementation CCAutoTrackSDK {
    NSString *_anonymousId;
}

static CCAutoTrackSDK *sharedInstance = nil;

+ (void)startWithServerURL:(NSString *)urlString {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CCAutoTrackSDK alloc] initWithServerURL:urlString];
    });
}

+ (CCAutoTrackSDK *)sharedInstance {
    return sharedInstance;
}

- (instancetype)initWithServerURL:(NSString *)urlString {
    self = [super init];
    if (self) {
        _automaticProperties = [self collectAutomaticProperties];
        
        // 标记是否被动启动
        _launchedPassively = UIApplication.sharedApplication.backgroundTimeRemaining != UIApplicationBackgroundFetchIntervalNever;
        
        // 从本地获取登录ID
        _loginId = [[NSUserDefaults standardUserDefaults] objectForKey:CCAutoTrackLoginId];
        // 获取设备ID（匿名ID）
        _anonymousId = [self anonymousId];
        
        _trackTimer = [NSMutableDictionary dictionary];
        _enterBackgroundTrackTimerEvents = [NSMutableArray array];
        _fileStore = [[CCAutoTrackFileStore alloc] init];
        // 初始化数据库对象，使用默认路径
        _database = [[CCAutoTrackDatabase alloc] init];
        // 此处需要配置一个可用的serverURL
        _network = [[CCAutoTrackNetwork alloc] initWithServerURL:[NSURL URLWithString:urlString]];
        
        // 调用异常处理的单例对象，进行初始化
        [CCAutoTrackExceptionHandler sharedInstance];
        
        NSString *queueLabel = [NSString stringWithFormat:@"cn.ccautotrack.%@.%p", self.class, self];
        _serialQueue = dispatch_queue_create([queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        _flushBulkSize = 100;
        _flushInterval = 9999;
        [self startFlushTimer];
        
        // 添加应用程序状态监听
        [self setupListener];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - properties

- (NSDictionary<NSString *, id> *)collectAutomaticProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 操作系统类型
    properties[@"$os"] = @"iOS";
    // SDK平台类型
    properties[@"$lib"] = @"iOS";
    // 设备制造商
    properties[@"$manufacturer"] = @"Apple";
    // SDK版本号
    properties[@"$lib_version"] = CCAutoTrackVersion;
    // 手机型号
    properties[@"$model"] = [self deviceModel];
    // 操作系统版本号
    properties[@"$os_version"] = UIDevice.currentDevice.systemVersion;
    // 应用程序版本号
    properties[@"$app_version"] = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return [properties copy];
}

+ (double)currentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

+ (double)systemUpTimer {
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

- (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

#pragma mark - listener

- (void)setupListener {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // 监听applicationDidFinishLaunching
    [center addObserver:self
               selector:@selector(applicationDidFinishLaunching:)
                   name:UIApplicationDidFinishLaunchingNotification
                 object:nil];
    
    // 监听applicationWillResignActive
    [center addObserver:self
               selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification
                 object:nil];
    
    // 监听applicationDidBecomeActive
    [center addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
    
    // 监听applicationDidEnterBackground
    [center addObserver:self
               selector:@selector(applicationDidEnterBackground:)
                   name:UIApplicationDidEnterBackgroundNotification
                 object:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"Application did finish launching.");
    
    // 当前程序后台启动时，触发被动启动事件
    if (self.isLaunchedPassively) {
        [self track:@"$AppStartPassively" properties:nil];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"Application did become active.");
    
    // 还原标记
    if (self.applicationWillResignActive) {
        self.applicationWillResignActive = NO;
        return;
    }
    
    // 将被动启动标记置为NO，记录正常事件
    self.launchedPassively = NO;
    
    // 触发$AppStart事件
    [self track:@"$AppStart" properties:nil];
    
    // 恢复所有事件时长统计
    for (NSString *event in self.enterBackgroundTrackTimerEvents) {
        [self trackTimerResume:event];
    }
    [self.enterBackgroundTrackTimerEvents removeAllObjects];
    
    // 开始$AppEnd事件计时
    [self trackTimerStart:@"$AppEnd"];
    
    // 开启计时器
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    NSLog(@"Application will resign active.");
    
    // 标记已收到UIApplicationWillResignActiveNotification本地通知
    self.applicationWillResignActive = YES;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"Application did enter background.");
    
    // 还原标记
    self.applicationWillResignActive = NO;
    
    // 触发$AppEnd事件
    [self trackTimerEnd:@"$AppEnd" properties:nil];
    
    UIApplication *application = UIApplication.sharedApplication;
    // 初始化标识符
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    // 结束后台任务
    void (^endBackgroundTask)(void) = ^() {
        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    };
    
    // 标记长时间运行的后台任务
    backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{
        endBackgroundTask();
    }];
    
    dispatch_async(self.serialQueue, ^{
        // 发送数据
        [self flushByEventCount:CCAutoTrackDefaultFlushEventCount background:YES];
        // 结束后台任务
        endBackgroundTask();
    });
    
    // 暂停所有事件时长统计
    [self.trackTimer enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj[CCAutoTrackEventIsPauseKey] boolValue]) {
            [self.enterBackgroundTrackTimerEvents addObject:key];
            [self trackTimerPause:key];
        }
    }];
    
    // 停止计时器
    [self stopFlushTimer];
}

#pragma mark - anonymousId

- (void)setAnonymousId:(NSString *)anonymousId {
    _anonymousId = anonymousId;
    // 保存设备ID
    [self saveAnonymousId:anonymousId];
}

- (NSString *)anonymousId {
    if (_anonymousId) {
        return _anonymousId;
    }
    
    // 从NSUserDefault读取设备ID
    _anonymousId = [[NSUserDefaults standardUserDefaults] objectForKey:CCAutoTrackAnonymousId];
    if (_anonymousId) {
        return _anonymousId;
    }
    
    // 从Keychain中读取设备ID
    CCAutoTrackKeychainItem *item = [[CCAutoTrackKeychainItem alloc] initWithService:CCAutoTrackKeychainService key:CCAutoTrackAnonymousId];
    _anonymousId = [item value];
    
    if (_anonymousId) {
        // 将设备ID保存在NSUserDefaults中
        [[NSUserDefaults standardUserDefaults] setObject:_anonymousId forKey:CCAutoTrackAnonymousId];
        // 返回保存的设备ID
        return _anonymousId;
    }
    
    // 获取IDFA
    // 用户可能没有导入AdSupport.framework
    Class cls = NSClassFromString(@"ASIdentifierManager");
    if (cls) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // 获取ASIdentifierManager的单例对象
        id manager = [cls performSelector:@selector(sharedManager)];
        SEL selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL (*isAdvertisingTrackingEnabled)(id, SEL) = (BOOL (*)(id, SEL))[manager methodForSelector:selector];
        if (isAdvertisingTrackingEnabled(manager, selector)) {
            // 使用IDFA作为设备ID
            _anonymousId = [(NSUUID *)[manager performSelector:@selector(advertisingIdentifier)] UUIDString];
        }
#pragma clang diagnostic pop
    }
    
    if (!_anonymousId) {
        // 使用IDFV作为设备ID
        _anonymousId = UIDevice.currentDevice.identifierForVendor.UUIDString;
    }
    
    if (!_anonymousId) {
        // 使用UUID作为设备ID
        _anonymousId = NSUUID.UUID.UUIDString;
    }
    
    // 保存设备ID
    [self saveAnonymousId:_anonymousId];
    
    return _anonymousId;
}

- (void)saveAnonymousId:(NSString *)anonymousId {
    // 保存设备ID到NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:anonymousId forKey:CCAutoTrackAnonymousId];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 保存设备ID到Keychain
    CCAutoTrackKeychainItem *item = [[CCAutoTrackKeychainItem alloc] initWithService:CCAutoTrackKeychainService key:CCAutoTrackAnonymousId];
    if (anonymousId) {
        // 当设备ID不为空时，将其保存在keychain中
        [item update:anonymousId];
    }else {
        // 当设备ID为空时，删除keychain中的值
        [item remove];
    }
}

#pragma mark - login

- (void)login:(NSString *)loginId {
    self.loginId = loginId;
    
    // 本地保存登录ID
    [[NSUserDefaults standardUserDefaults] setObject:loginId forKey:CCAutoTrackLoginId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - flush

- (void)flush {
    dispatch_async(self.serialQueue, ^{
        // 默认向服务端发送50条数据
        [self flushByEventCount:CCAutoTrackDefaultFlushEventCount background:NO];
    });
}

- (void)flushByEventCount:(NSUInteger)count background:(BOOL)background {
    if (background) {
        __block BOOL isContinue = YES;
        dispatch_sync(dispatch_get_main_queue(), ^{
            isContinue = UIApplication.sharedApplication.backgroundTimeRemaining >= 30;
        });
        if (!isContinue) {
            return;
        }
    }
    
    // 获取本地数据
    NSArray<NSString *> *events = [self.database selectEventsForCount:count];
    // 当本地存储的数据为0或者上传失败时，直接返回，退出递归调用
    if (events.count == 0 || ![self.network flushEvents:events]) {
        return;
    }
    
    // 当删除数据失败时，直接返回，退出递归调用，防止死循环
    if (![self.database deleteEventsForCount:count]) {
        return;
    }
    
    // 继续上传本地其他数据
    [self flushByEventCount:count background:background];
}

- (void)startFlushTimer {
    if (self.flushTimer) {
        return;
    }
    
    NSTimeInterval interval = self.flushInterval < 5 ? 5 : self.flushInterval;
    self.flushTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(flush) userInfo:nil repeats:YES];
    [NSRunLoop.currentRunLoop addTimer:self.flushTimer forMode:NSRunLoopCommonModes];
}

- (void)stopFlushTimer {
    [self.flushTimer invalidate];
    self.flushTimer = nil;
}

- (void)setFlushInterval:(NSUInteger)flushInterval {
    if (_flushInterval != flushInterval) {
        // 上传本地缓存的所有数据
        [self flush];
        // 先暂停计时器
        [self stopFlushTimer];
        // 重新开启计时器
        [self startFlushTimer];
    }
}

@end

#pragma mark - Track

@implementation CCAutoTrackSDK (Track)

- (void)track:(NSString *)eventName properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    
    // 设置事件的distinct_id，用于唯一标识一个用户
    event[@"distinct_id"] = self.loginId ?: self.anonymousId;
    // 设置事件名称
    event[@"event"] = eventName;
    // 设置事件发生的时间戳，单位毫秒
    event[@"time"] = [NSNumber numberWithLong:NSDate.date.timeIntervalSince1970 * 1000];
    
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    // 添加预置属性
    [eventProperties addEntriesFromDictionary:self.automaticProperties];
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 设置事件属性
    
    // 判断是否为被动启动状态
    if (self.isLaunchedPassively) {
        // 添加应用程序状态
        eventProperties[@"$app_state"] = @"background";
    }
    
    // 设置事件属性
    event[@"properties"] = eventProperties;
    
    dispatch_async(self.serialQueue, ^{
        // 在Xcode控制台打印事件日志
        [self printEvent:event];
        
        // 使用文件保存事件数据
        // [self.fileStore saveEvent:event];
        
        // 使用数据库保存事件数据
        [self.database insertEvent:event];
    });
    
    if (self.database.eventCount >= self.flushBulkSize) {
        [self flush];
    }
}

- (void)trackAppClickWithView:(UIView *)view properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    
    // 设置控件类型
    eventProperties[@"$element_type"] = view.cc_elementType;
    // 设置控件内容
    eventProperties[@"$element_content"] = view.cc_elementContent;
    // 设置页面相关属性
    UIViewController *vc = view.cc_viewController;
    eventProperties[@"$screen_name"] = NSStringFromClass(vc.class);
    
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发$AppClick事件
    [[CCAutoTrackSDK sharedInstance] track:@"$AppClick" properties:eventProperties];
}

- (void)trackAppClickWithTableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    
    // 获取用户点击的UITableViewCell控件对象
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // 设置被用户点击的UITableViewCell控件上的内容
    eventProperties[@"$element_content"] = cell.cc_elementContent;
    
    // 设置被用户点击的UITableViewCell控件所在的位置
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发$AppClick事件
    [self trackAppClickWithView:tableView properties:eventProperties];
}

- (void)trackAppClickWithCollectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath properties:(nullable NSDictionary<NSString *, id> *)properties {
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    
    // 获取用户点击的UICollectionViewCell控件对象
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    // 设置被用户点击的UITableViewCell控件上的内容
    eventProperties[@"$element_content"] = cell.cc_elementContent;
    
    // 设置被用户点击的UICollectionViewCell控件所在的位置
    eventProperties[@"$element_position"] = [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    
    // 添加自定义属性
    [eventProperties addEntriesFromDictionary:properties];
    // 触发$AppClick事件
    [self trackAppClickWithView:collectionView properties:eventProperties];
}

- (void)printEvent:(NSDictionary *)event {
#if DEBUG
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"JSON Serialized Error: %@", error);
    }
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[event]: %@", json);
#endif
}

@end

#pragma mark - Timer

@implementation CCAutoTrackSDK (Timer)

- (void)trackTimerStart:(NSString *)event {
    // 记录事件开始时间
    self.trackTimer[event] = @{CCAutoTrackEventBeginKey: @([CCAutoTrackSDK systemUpTimer])};
}

- (void)trackTimerPause:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimer[event] mutableCopy];
    
    // 如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    
    // 如果已经暂停，直接返回
    if ([eventTimer[CCAutoTrackEventIsPauseKey] boolValue]) {
        return;
    }
    
    double beginTime = [eventTimer[CCAutoTrackEventBeginKey] doubleValue];
    double currentTime = [CCAutoTrackSDK systemUpTimer];
    
    // 计算暂停前统计的时长
    double duration = [eventTimer[CCAutoTrackEventDurationKey] doubleValue] + currentTime - beginTime;
    eventTimer[CCAutoTrackEventDurationKey] = @(duration);
    
    // 事件处于暂停状态
    eventTimer[CCAutoTrackEventIsPauseKey] = @(YES);
    self.trackTimer[event] = eventTimer;
}

- (void)trackTimerResume:(NSString *)event {
    NSMutableDictionary *eventTimer = [self.trackTimer[event] mutableCopy];
    
    // 如果没有开始，直接返回
    if (!eventTimer) {
        return;
    }
    
    // 如果已经继续，直接返回
    if (![eventTimer[CCAutoTrackEventIsPauseKey] boolValue]) {
        return;
    }
    
    double currentTime = [CCAutoTrackSDK systemUpTimer];
    // 重置事件开始时间
    eventTimer[CCAutoTrackEventBeginKey] = @(currentTime);
    
    // 事件处于继续状态
    eventTimer[CCAutoTrackEventIsPauseKey] = @(NO);
    self.trackTimer[event] = eventTimer;
}

- (void)trackTimerEnd:(NSString *)event properties:(NSDictionary<NSString *,id> *)propedrties {
    NSDictionary *eventTimer = self.trackTimer[event];
    if (!eventTimer) {
        return [self track:event properties:propedrties];
    }
    
    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:propedrties];
    // 移除
    [self.trackTimer removeObjectForKey:event];
    
    // 判断当前是否处于暂停状态
    if ([eventTimer[CCAutoTrackEventIsPauseKey] boolValue]) {
        // 获取事件时长
        double duration = [eventTimer[CCAutoTrackEventDurationKey] doubleValue];
        // 设置时长属性
        p[@"$event_duration"] = @([[NSString stringWithFormat:@"%.3lf", duration] floatValue]);
    } else {
        // 事件开始时间
        double beginTime = [eventTimer[CCAutoTrackEventBeginKey] doubleValue];
        // 当前时间
        double currentTime = [CCAutoTrackSDK systemUpTimer];
        // 计算时长
        double duration = [eventTimer[CCAutoTrackEventDurationKey] doubleValue] + currentTime - beginTime;
        // 设置时长属性
        p[@"$event_duration"] = @([[NSString stringWithFormat:@"%.3lf", duration] floatValue]);
    }
    
    // 触发事件
    [self track:event properties:p];
}

@end
