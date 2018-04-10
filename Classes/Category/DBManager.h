//
//  DBManager.h
//  PracticeOC
//
//  Created by xt on 2016/4/18.
//  Copyright © 2016年 xt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
@interface DBManager : NSObject
@property (nonatomic, strong) FMDatabase *db;

/**
 * 获取数据库操作类对象
 *
 * @return 数据库管理对象
 */
+ (DBManager *)sharedDBManager;//单例

/**
 * 创建表
 *
 * @param c 类的class
 */
-(void)createTable:(Class)c;//类创建表

/**
 * 插入数据
 *
 * @param obj 需要插入的对象
 */
-(void)insertRecord:(id)obj;//添加数据

/**
 * 选择数据
 *
 * @param c 类的class
 *
 * @return 查询得到的类对象数组
 */
-(NSMutableArray *)selectAllRecord:(Class)c;//全部查询

/**
 * 选择符合条件的数据
 *
 * @param c 类的class
 * @param params 查询条件的集合
 *
 * @return 满足条件的类对象数组
 */
-(NSMutableArray *)selectRecord:(Class)c withParams:(NSDictionary *)params;//条件查询

/**
 * 删除对应类的全部数据
 *
 * @param c 类的class
 */
-(void)deleteAllRecord:(Class)c;//删除全部数据

/**
 * 删除满足条件的对应类数据
 *
 * @param c 类的class
 * @param params 查询条件的集合
 *
 */
-(void)deleteRecord:(Class)c withParams:(NSDictionary *)params;//条件删除

/**
 * 更新数据
 *
 * @param obj 要更新的的数据对象
 * @param params 更新的数据需要满足的条件
 */
-(void)updateRecord:(id)obj withParams:(NSDictionary *)params;//修改数据


@end
