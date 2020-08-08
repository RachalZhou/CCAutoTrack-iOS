//
//  CCAutoTrackDatabase.m
//  CCAutoTrack
//
//  Created by 周日朝 on 2020/8/1.
//  Copyright © 2020 周日朝. All rights reserved.
//

#import "CCAutoTrackDatabase.h"

static NSString * const CCAutoTrackDefaultDatabaseName = @"CCAutoTrackDatabase.sqlite";

static sqlite3_stmt *insertStmt = NULL;
static sqlite3_stmt *selectStmt = NULL;
static NSUInteger lastSelectEventCount = 50;

@interface CCAutoTrackDatabase ()

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation CCAutoTrackDatabase {
    sqlite3 *_database;
}

- (instancetype)init {
    return [self initWithFilePath:nil];
}

- (instancetype)initWithFilePath:(nullable NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = filePath ?: [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:CCAutoTrackDefaultDatabaseName];
        
        // 初始化队列的唯一标识
        NSString *label = [NSString stringWithFormat:@"cn.cc.serialQueue.%p", self];
        // 创建一个serial类型的queue，即FIFO
        _queue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
        [self open];
        [self queryLocalDatabaseEventCount];
        
        NSLog(@"数据库缓存路径%@", _filePath);
    }
    return self;
}

- (void)open {
    dispatch_async(self.queue, ^{
        // 初始化SQLite数据库
        if (sqlite3_initialize() != SQLITE_OK) {
            return;
        }
        
        // 打开数据库，获取数据库指针
        if (sqlite3_open_v2([self.filePath UTF8String], &(self->_database), SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
            return NSLog(@"SQLite stmt prepare error:%s", sqlite3_errmsg(self.database));
        }
        
        char *error;
        // 创建数据库表的SQL语句
        NSString *sql = @"CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, event BLOB);";
        // 运行创建表格的SQL语句
        if (sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, &error) != SQLITE_OK) {
            return NSLog(@"Create events Failure %s", error);
        }
    });
}

- (void)queryLocalDatabaseEventCount {
    dispatch_async(self.queue, ^{
        // 查询语句
        NSString *sql = @"SELECT count(*) FROM events;";
        sqlite3_stmt *stmt = NULL;
        
        if (sqlite3_prepare(self.database, sql.UTF8String, -1, &stmt, NULL) != SQLITE_OK) {
            return NSLog(@"SQLite stmt prepare error %s", sqlite3_errmsg(self.database));
        }
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            self.eventCount = sqlite3_column_int(stmt, 0);
        }
    });
}

- (void)insertEvent:(NSDictionary *)event {
    dispatch_async(self.queue, ^{
        if (insertStmt) {
            // 重置插入语句，重置之后可重新绑定数据
            sqlite3_reset(insertStmt);
        } else {
            // 插入语句
            NSString *sql = @"INSERT INTO events (event) values (?)";
            // 准备执行SQL语句，获取sqlite3_stmt
            if (sqlite3_prepare_v2(self.database, sql.UTF8String, -1, &insertStmt, NULL) != SQLITE_OK) {
                return NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
            }
        }
        
        NSError *error = nil;
        // 将event转换成JSON数据
        NSData *data = [NSJSONSerialization dataWithJSONObject:event options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            return NSLog(@"JSON Serialization error: %@", error);
        }
        
        // 将JSON数据与stmt绑定
        sqlite3_bind_blob(insertStmt, 1, data.bytes, (int)data.length, SQLITE_TRANSIENT);
        // 执行stmt
        if (sqlite3_step(insertStmt) != SQLITE_DONE) {
            return NSLog(@"Insert event to events error");
        }
        
        // 数据插入成功，事件数量加一
        self.eventCount++;
    });
}

- (NSArray<NSString *> *)selectEventsForCount:(NSUInteger)count {
    // 初始化数组，用于存储查询到的事件数据
    NSMutableArray<NSString *> *events = [NSMutableArray arrayWithCapacity:count];
    // ▽ 这里需要使用dispatch_sync函数，不能使用dispatch_async函数，否则会导致返回的事件不完整
    dispatch_sync(self.queue, ^{
        // 当本地事件数量为0时，直接返回
        if (self.eventCount == 0) {
            return;
        }
        
        if (count != lastSelectEventCount) {
            lastSelectEventCount = count;
            selectStmt = NULL;
        }
        
        if (selectStmt) {
            // 重置查询语句
            sqlite3_reset(selectStmt);
        } else {
            // 查询语句
            NSString *sql = [NSString stringWithFormat:@"SELECT id, event FROM events ORDER BY id ASC LIMIT %lu", (unsigned long)count];
            // 准备执行SQL语句，获取sqlite3_stmt
            if (sqlite3_prepare(self.database, [sql UTF8String], -1, &selectStmt, NULL) != SQLITE_OK) {
                return NSLog(@"SQLite stmt prepare error: %s", sqlite3_errmsg(self.database));
            }
        }
        
        // 执行SQL语句
        while (sqlite3_step(selectStmt) == SQLITE_ROW) {
            // 将当前查询的这条数据转换成NSData对象
            NSData *data = [[NSData alloc] initWithBytes:sqlite3_column_blob(selectStmt, 1) length:sqlite3_column_bytes(selectStmt, 1)];
            // 查询到的事件数据转换成JSON字符串
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#ifdef DEBUG
            NSLog(@"%@", jsonString);
#endif
            // 将JSON字符串添加到数组中
            [events addObject:jsonString];
        }
    });
    return events;
}

- (BOOL)deleteEventsForCount:(NSUInteger)count {
    __block BOOL success = YES;
    dispatch_sync(self.queue, ^{
        // 当本地事件数量为0时，直接返回
        if (self.eventCount == 0) {
            return;
        }
        // 删除语句
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM events WHERE id IN (SELECT id FROM events ORDER BY id ASC LIMIT %lu);", (unsigned long)count];
        char *errmsg;
        // 执行删除语句
        if (sqlite3_exec(self.database, sql.UTF8String, NULL, NULL, &errmsg) != SQLITE_OK) {
            success = NO;
            return NSLog(@"Failed to delete record msg=%s", errmsg);
        }
        self.eventCount = self.eventCount < count ? 0 : self.eventCount - count;
    });
    return success;
}

@end
