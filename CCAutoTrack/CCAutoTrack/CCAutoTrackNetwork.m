//
//  CCAutoTrackNetwork.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/8/2.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackNetwork.h"

/// 网络请求结束处理回调类型
typedef void(^CCURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);

@interface CCAutoTrackNetwork ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation CCAutoTrackNetwork

- (instancetype)initWithServerURL:(NSURL *)serverURL {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        
        // 创建默认的session配置对象
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 设置单个主机连接数为5
        configuration.HTTPMaximumConnectionsPerHost = 5;
        // 设置请求超时时间
        configuration.timeoutIntervalForRequest = 30;
        // 允许使用蜂窝移动网络
        configuration.allowsCellularAccess = YES;
        
        // 创建一个网络请求回调和完成操作的线程池
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        // 设置同步运行的最大操作数为1，即FIFO
        queue.maxConcurrentOperationCount = 1;
        // 通过配置对象创建一个session对象
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    }
    return self;
}

- (NSString *)buildJSONStringWitnEvents:(NSArray<NSString *> *)events {
    return [NSString stringWithFormat:@"[\n%@\n]", [events componentsJoinedByString:@",\n"]];
}

- (NSURLRequest *)buildRequestWithJSONString:(NSString *)json {
    // 通过服务器地址创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.serverURL];
    // 设置请求的body
    request.HTTPBody = [json dataUsingEncoding:NSUTF8StringEncoding];
    // 设置请求方式
    request.HTTPMethod = @"POST";
    return request;
}

- (BOOL)flushEvents:(NSArray<NSString *> *)events {
    // 将事件数组组装成JSON字符串
    NSString *jsonString = [self buildJSONStringWitnEvents:events];
    // 创建请求对象
    NSURLRequest *request = [self buildRequestWithJSONString:jsonString];
    
    // 使用GCD信号量，实现线程锁
    dispatch_semaphore_t flushSemaphore = dispatch_semaphore_create(0);
    
    // 数据上传结果
    __block BOOL flushSuccess = NO;
    CCURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            // 请求出错时，打印错误信息
            NSLog(@"Flush events error %@", error);
            dispatch_semaphore_signal(flushSemaphore);
            return;
        }
        
        // 获取请求结果返回的状态码
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        // 当状态码为2xx时，表示事件发送成功
        if (statusCode >= 200 && statusCode < 300) {
            // 打印上传成功的数据
            NSLog(@"Flush events success: %@", jsonString);
            // 数据上传成功
            flushSuccess = YES;
        } else {
            // 事件发送失败
            NSString *desc = [NSString stringWithFormat:@"Flush events error, statusCode: %d, events: %@", (int)statusCode, jsonString];
            NSLog(@"%@", desc);
        }
        
        dispatch_semaphore_signal(flushSemaphore);
    };
    
    // 通过request创建请求任务
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:handler];
    // 执行任务
    [task resume];
    // 等待请求完成
    dispatch_semaphore_wait(flushSemaphore, DISPATCH_TIME_FOREVER);
    
    return flushSuccess;
}

@end
