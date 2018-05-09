//
//  YVPaymentManager.h
//  YVPaymentTool
//
//  Created by 周荣飞 on 2018/5/5.
//  Copyright © 2018年 YoonveyTest. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YVReceiptUtils.h"

typedef enum
{
    PayPlatformOfAlipay,//支付宝
    PayPlatformOfWechat,//微信
    PayPlatformOfAppPay,//苹果内购
    PayPlatformOfCustom//自定义
}PayPlatform;

@protocol YVPaymentDelegate <NSObject>

@optional

/*!
 * brief 返回授权回调信息
 * @param platform 支付平台
 */
- (void)managerDidResponseAuthResult:(NSDictionary *)resultDic
                            platform:(PayPlatform)platform;

/*!
 * @brief 返回支付回调信息
 * @param resultDic 支付回调信息, 若支付成功,返回outTradeNo,tradeNo,memo; 反之则只返回memo备注
 * @param platform 支付平台
 */
- (void)managerDidResponsePayResult:(NSDictionary *)resultDic
                           platform:(PayPlatform)platform;

@end

@interface YVPaymentManager : NSObject

@property (nonatomic) id<YVPaymentDelegate> delegate;

@property (nonatomic) BOOL aliPay;//是否注册支付宝支付(请在初始化完成设置)
@property (nonatomic) BOOL wechatPay;//是否注册微信支付(请在初始化完成设置)

+ (instancetype)sharedManager;

#pragma mark - <Configuration-请在AppDelegate中调用>
- (BOOL)application:(UIApplication *)application
      handleOpenUrl:(NSURL *)url;

//仅支持ios9以上系统支付回调
- (BOOL)application:(UIApplication *)application
            openUrl:(nonnull NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;

//支持所有ios 系统支付回调
- (BOOL)application:(UIApplication *)application
            openUrl:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;

#pragma mark - <Instance>
/*!
 * @brief 生成支付宝支付订单后跳转到APP进行支付
 * @param orderString 订单信息
 * @param confirmId 查询
 * @param appScheme 应用注册scheme
 */
- (void)responderOfInvokingAlipayWithOrderSign:(NSString *)orderString
                                        object:(NSString *)confirmId
                                   objectValue:(NSString *)confirmValue
                                     appScheme:(NSString *)appScheme;

/*!
 * @brief 生成微信支付订单后跳转到APP进行支付
 * @note dict订单信息中的字段,请根据后台实际情况进行设置
 */
- (void)responderOfInvokingWechatpayWithPayInfoDictionary:(NSDictionary *)dict;

/*!
 * @brief 启用应用内支付查询商品
 * @param productIdentifier 商品唯一标示
 */
- (void)responderOfInvokingIAPPaymentWithProductIdentifier:(NSString *)productIdentifier;

@end
