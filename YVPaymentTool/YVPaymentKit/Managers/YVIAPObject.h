//
//  YVIAPObject.h
//  YVPaymentTool
//
//  Created by 周荣飞 on 2018/5/5.
//  Copyright © 2018年 YoonveyTest. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <StoreKit/StoreKit.h>

@protocol YVIAPDelegate <NSObject>

@optional

/*!
 * @brief 交易请求回调
 * @param msg 交易状态描述
 */
- (void)transactionDidResponseState:(NSString *)msg;

@end

@interface YVIAPObject : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

@property (nonatomic, assign) id<YVIAPDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *receipt;

- (BOOL)canMakePayments;

/*!
 * @brief 获取商品列表
 * @param productIdentifier 商品唯一标示
 */
- (void)getProductInfo:(NSString *)productIdentifier;

@end
