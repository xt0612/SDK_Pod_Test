//
//  DBManager.m
//  PracticeOC
//
//  Created by xt on 2016/4/18.
//  Copyright © 2016年 xt. All rights reserved.
//

#import "DBManager.h"
#import <objc/runtime.h>
#import "FMDB.h"

static DBManager *_instance;

@interface DBManager ()


@end


@implementation DBManager

- (id)init{
    if(self = [super init]){
        //创建数据库
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documents = [paths objectAtIndex:0];
        NSString *dbPath = [documents stringByAppendingPathComponent:@"data.db"];
        self.db = [FMDatabase databaseWithPath:dbPath];
    }
    return self;
}

+ (DBManager *)sharedDBManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (NSString *)fetchTableName:(Class)c{
    const char *tableName = class_getName(c);
    NSString *tableNameStr =[[NSString alloc] initWithUTF8String:tableName];
    return tableNameStr;
}

-(void)insertRecord:(id)obj{
    if([self.db open]){//数据库打开，开始操作
        NSString *tableNameStr =[self fetchTableName:[obj class]];
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(",tableNameStr];
        NSString *sqlValues =@"(";
        unsigned int count = 0;
        Ivar *ivarList = class_copyIvarList([obj class],&count);
        for (int i=0; i<count; i++){
            Ivar ivar =  ivarList[i];
            NSString *key =  [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%@",key]];
            sqlValues =[sqlValues stringByAppendingString:[NSString stringWithFormat:@"'%@'",[obj valueForKey:key]]];
            if(i!=(count-1)){
                sql = [sql stringByAppendingString:@","];
                sqlValues = [sqlValues stringByAppendingString:@","];
            }
        }
        sql = [NSString stringWithFormat:@"%@) VALUES %@)",sql,sqlValues];
        free(ivarList);
        [self.db executeUpdate:sql];
        [self.db open];//操作数据库完成之后关闭
    }
}

-(NSMutableArray *)selectAllRecord:(Class)c{
    return  [self selectRecord:c withParams:nil];
}

-(NSMutableArray *)selectRecord:(Class)c withParams:(NSDictionary *)params{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count;
    Ivar *ivarList = class_copyIvarList(c,&count);
    if([self.db open]){
        NSMutableString *condition = [@"1=1" mutableCopy];
        if(params != nil){
            for (NSString *key in params.allKeys) {
                [condition appendFormat:@" and %@=%@", [@"_" stringByAppendingString:key], params[key]];
            }
        }
        NSString *tableNameStr =[self fetchTableName:c];
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@",tableNameStr, condition];
        FMResultSet *result=[self.db executeQuery:sql];
        while(result.next){
            id obj = [[c alloc] init];
            for (int i = 1; i <= count; i++){
                Ivar ivar =  ivarList[(i-1)];
                NSString *key =  [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
                NSString *valueStr = [result stringForColumn:key];
                [obj setValue:valueStr forKeyPath:key];
            }
            [array addObject:obj];
        }
        [self.db close];
    }
    return array;
}

-(void)createTable:(Class)c{
    if([self.db open]){
        NSString *sql = @"
        const char *tableName = class_getName(c);
        sql = [sql stringByAppendingString:[[NSString alloc] initWithUTF8String:tableName]];
        sql = [sql stringByAppendingString:@"(ID INTEGER PRIMARY KEY AUTOINCREMENT,"];
        unsigned int count = 0;
        Ivar *ivarList = class_copyIvarList(c,&count);
        for (int i = 0; i <count; i++){
            Ivar ivar =  ivarList[i];
            NSString *key =  [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%@ TEXT",key]];
            if(i != (count-1))
                sql = [sql stringByAppendingString:@","];
        }
        free(ivarList);
        sql = [sql stringByAppendingString:@")"];
        [self.db executeUpdate:sql];
        [self.db  close];
    }
}

-(void)deleteAllRecord:(Class)c{
    [self deleteRecord:c withParams:nil];
}

-(void)deleteRecord:(Class)c withParams:(NSDictionary *)params{
    if([self.db open]){
        NSMutableString *condition = [@"1 = 1" mutableCopy];
        if(params != nil){
            for (NSString *key in params.allKeys) {
                [condition appendFormat:@" and %@ = %@", [@"_" stringByAppendingString:key], params[key]];
            }
        }
        NSString *tableNameStr =[self fetchTableName:c];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", tableNameStr, condition];
        [self.db executeUpdate:sql];
        [self.db close];
    }
}

-(void)updateRecord:(id)obj withParams:(NSDictionary *)params{
    if([self.db open]){
        NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ", [self fetchTableName:[obj class]]];
        unsigned int count = 0;
        Ivar *ivarList = class_copyIvarList([obj class],&count);
        for (int i = 0; i < count; i++) {
            Ivar ivar =  ivarList[i];
            NSString *key =  [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
            [sql appendFormat:@"%@ = '%@'", key, [obj valueForKey:[key substringFromIndex:1]]];
            if(i != count - 1)
               [sql appendString:@","];
        }
        if(params != nil){
            [sql appendFormat:@" WHERE 1 = 1"];
            NSArray *allKeys = params.allKeys;
            for (NSString *key in allKeys) {
                [sql appendFormat:@" and %@ = '%@'", [@"_" stringByAppendingString:key], params[key]];
            }
        }
        [self.db executeUpdate:sql];
        [self.db close];
    }
}

@end
