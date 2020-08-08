//
//  CCAutoTrackFileStore.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/8/1.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackFileStore.h"

static NSString * const CCAutoTrackDefaultFileName = @"CCAutoTrackData.plist";

@interface CCAutoTrackFileStore ()

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *events;

/// 串行队列
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation CCAutoTrackFileStore

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化默认的事件数据存储地址
        _filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:CCAutoTrackDefaultFileName];
        
        // 初始化队列的唯一标识
        NSString *label = [NSString stringWithFormat:@"cn.cc.serialQueue.%p", self];
        // 创建一个serial类型的queue，即FIFO
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // 从文件路径中读取数据
        [self readAllEventsFromFilePath:_filePath];
        
        // 初始化本地缓存最大条数
        _maxLocalEventCount = 10000;
        
        NSLog(@"文件缓存路径%@", _filePath);
    }
    return self;
}

- (void)readAllEventsFromFilePath:(NSString *)filePath {
    dispatch_async(self.queue, ^{
        // 从文件路径读取数据
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (data) {
            // 解析文件中读取的Json数据
            NSMutableArray *allEvents = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            // 将文件中的数据保存在内存中
            self.events = allEvents ?: [NSMutableArray array];
        }else {
            self.events = [NSMutableArray array];
        }
    });
}

- (void)saveEvent:(NSDictionary *)event {
    dispatch_async(self.queue, ^{
        // 判断当前条数是否超过最大值，超过则删除最旧的
        if (self.events.count >= self.maxLocalEventCount) {
            [self.events removeObjectAtIndex:0];
        }
        
        // 添加事件数据到数组
        [self.events addObject:event];
        // 将事件数据保存到文件中
        [self writeEventsToFile];
    });
}

- (void)writeEventsToFile {
    // 将字典解析成Jsong数据
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.events options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        return NSLog(@"The json object's serialization error %@", error);
    }
    
    // 将数据写入文件
    [data writeToFile:self.filePath atomically:YES];
}

- (void)deleteEventsForCount:(NSInteger)count {
    dispatch_async(self.queue, ^{
        // 删除前count条数据
        [self.events removeObjectsInRange:NSMakeRange(0, count)];
        // 将删除后剩余的事件保存到文件中
        [self writeEventsToFile];
    });
}

- (NSArray<NSDictionary *> *)allEvents {
    __block NSArray<NSDictionary *> *allEvents = nil;
    // 同步，保证线程安全
    dispatch_sync(self.queue, ^{
        allEvents = [self.events copy];
    });
    return allEvents;
}

@end
