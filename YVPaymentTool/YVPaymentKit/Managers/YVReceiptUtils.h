//
//  YVReceiptUtils.h
//  YVPaymentTool
//
//  Created by 周荣飞 on 2018/5/5.
//  Copyright © 2018年 YoonveyTest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YVReceiptUtils : NSObject

/*!
 * @brief 持久化存储用户购买凭证(这里最好还要存储当前日期，用户id等信息，用于区分不同的凭证)
 * @param receipt 凭证信息
 * @param userId 用户Id
 * @return 保存是否成功
 */
+ (BOOL)saveReceipt:(NSString *)receipt
            forUser:(NSString *)userId;

/*!
 * @brief 获取验证失败的用户购买凭证文件路径
 * @return 文件路径
 */
+ (NSString *)getFailedIAPFilePath;

/*!
 * @brief 移除已经验证成功的购买凭证
 * @return 移除是否成功
 */
+ (BOOL)removeReceiptFilePath;

@end
