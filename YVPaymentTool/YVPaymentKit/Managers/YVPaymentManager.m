//
//  YVPaymentManager.m
//  YVPaymentTool
//
//  Created by 周荣飞 on 2018/5/5.
//  Copyright © 2018年 YoonveyTest. All rights reserved.
//

#import "YVPaymentManager.h"

#import <AlipaySDK/AlipaySDK.h>
#import "WXApiObject.h"
#import "WXApiManager.h"
#import "YVIAPObject.h"

@interface YVPaymentManager ()<WXApiManagerDelegate, YVIAPDelegate>

@property (nonatomic, copy) NSString *wxOutTradeNo;//微信商户订单号,由服务器返回
@property (nonatomic, strong) YVIAPObject *iAPobject;

@end

@implementation YVPaymentManager

- (YVIAPObject *)iAPobject
{
    if(!_iAPobject)
    {
        _iAPobject = [[YVIAPObject alloc]init];
        _iAPobject.delegate = self;
    }
    return _iAPobject;
}

#pragma mark - <创建单例>
+ (instancetype)sharedManager
{
    static dispatch_once_t token;
    static YVPaymentManager *manager;
    dispatch_once(&token, ^
    {
        manager = [[YVPaymentManager alloc]init];
    });
    return manager;
}

- (void)dealloc
{
    _delegate = nil;
    if (_iAPobject)
    {
        _iAPobject.delegate = nil;
    }
}

#pragma mark - <扩展方法>
NSDictionary *DictionaryWithJsonString(NSString *jsonString)
{
    if (jsonString == nil)
    {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if(error)
    {
        NSLog(@"jsonString>%@",jsonString);
        NSLog(@"dictionaryjson解析失败：%@",error);
        return nil;
    }
    return dic;
}

NSDictionary *AlipayProcessOrderWithPaymentResult(NSDictionary *resultDic)
{
    NSString *resultStatus = [resultDic objectForKey:@"resultStatus"];
    NSString *memo = nil;
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    if ([resultStatus intValue] == 9000)
    {
        memo = @"支付成功!";
        NSDictionary *resultInfo = DictionaryWithJsonString(resultDic[@"result"]);
        NSDictionary *tradeAppPayResponse = resultInfo[@"alipay_trade_app_pay_response"];
        NSString *outTradeNo = tradeAppPayResponse[@"out_trade_no"];
        NSString *tradeNo = tradeAppPayResponse[@"trade_no"];
        
        NSLog(@"resultInfo>%@", resultInfo);
        NSLog(@"outTradeNo>%@", outTradeNo);
        NSLog(@"tradeNo>%@", tradeNo);
        
        [result setValue:outTradeNo forKey:@"outTradeNo"];
        [result setValue:tradeNo forKey:@"tradeNo"];
        [result setValue:memo forKey:@"memo"];
        
        return result;
    }
    else
    {
        switch ([resultStatus intValue])
        {
            case 4000:
                memo = @"订单支付失败!";
                break;
            case 6001:
                memo = @"用户中途取消!";
                break;
            case 6002:
                memo = @"网络连接出错!";
                break;
            case 8000:
                memo = @"正在处理中...";
                break;
            default:
                memo = [resultDic objectForKey:@"memo"];
                break;
        }
        [result setValue:memo forKey:@"memo"];
        return result;
    }
}

#pragma mark - <支付App回调>
- (BOOL)application:(UIApplication *)application handleOpenUrl:(NSURL *)url
{
    if (self.wechatPay)
    {
        return [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application openUrl:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if (self.wechatPay)
    {
        [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
    }
    //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
    if ([url.host isEqualToString:@"platformapi"])//支付宝钱包快登授权返回 authCode
    {
        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic)
        {
            NSLog(@"授权结果回调 = %@",resultDic);
            if (self.delegate && [self.delegate respondsToSelector:@selector(managerDidResponseAuthResult:platform:)])
            {
                [self.delegate managerDidResponseAuthResult:resultDic platform:PayPlatformOfAlipay];
            }
        }];
    }
    if ([url.host isEqualToString:@"safepay"])//安全支付回调
    {
         //支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic)
         {
             NSLog(@"支付跳转支付宝钱包进行支付.result = %@",resultDic);
             // 解析 auth code
             NSString *result = resultDic[@"result"];
             NSString *authCode = nil;
             if (result.length>0)
             {
                 NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                 for (NSString *subResult in resultArr)
                 {
                     if (subResult.length>10 && [subResult hasPrefix:@"auth_code="])
                     {
                         authCode = [subResult substringFromIndex:10];
                         break;
                     }
                 }
             }
             NSLog(@"授权结果 authCode = %@", authCode?:@"");
         }];
        // 处理授权信息
        [[AlipaySDK defaultService]processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic)
         {
             NSLog(@"回调结果 = %@",resultDic);
             if (self.delegate && [self.delegate respondsToSelector:@selector(managerDidResponseAuthResult:platform:)])
             {
                 [self.delegate managerDidResponseAuthResult:resultDic platform:PayPlatformOfAlipay];
             }
         }];
        return YES;
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application openUrl:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (self.wechatPay)
    {
        [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
    }
    //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
    if ([url.host isEqualToString:@"safepay"])
    {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic)
         {
             NSLog(@"支付跳转支付宝钱包进行支付.result = %@",resultDic);
             NSDictionary *result = AlipayProcessOrderWithPaymentResult(resultDic);
             if (self.delegate && [self.delegate respondsToSelector:@selector(managerDidResponsePayResult:platform:)])
             {
                 [self.delegate managerDidResponsePayResult:result platform:PayPlatformOfAlipay];
             }
         }];
        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic)
         {
             NSLog(@"授权支付宝钱包支付.result = %@",resultDic);
             // 解析 auth code
             NSString *result = resultDic[@"result"];
             NSString *authCode = nil;
             if (result.length>0)
             {
                 NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                 for (NSString *subResult in resultArr)
                 {
                     if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="])
                     {
                         authCode = [subResult substringFromIndex:10];
                         break;
                     }
                 }
             }
             NSLog(@"授权结果 authCode = %@", authCode?:@"");
         }];
        return YES;
    }
    return NO;
}

#pragma mark - <调用客户端支付>
//生成支付宝支付订单后跳转到APP生成支付
- (void)responderOfInvokingAlipayWithOrderSign:(NSString *)orderString
                                        object:(NSString *)confirmId
                                   objectValue:(NSString *)confirmValue
                                     appScheme:(NSString *)appScheme
{
    //应用注册scheme,在AliSDKDemo-Info.plist定义URL types
    // NOTE: 调用支付结果开始支付
    [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic)
     {
         NSLog(@"支付宝支付回调 :%@",resultDic[@"memo"]);
         NSDictionary *result = AlipayProcessOrderWithPaymentResult(resultDic);
         if (self.delegate && [self.delegate respondsToSelector:@selector(managerDidResponsePayResult:platform:)])
         {
             [self.delegate managerDidResponsePayResult:result platform:PayPlatformOfAlipay];
         }
     }];
}

//生成微信支付订单后跳转到APP生成支付
- (void)responderOfInvokingWechatpayWithPayInfoDictionary:(NSDictionary *)dict
{
    self.wxOutTradeNo = dict[@"outtradeno"];//商户订单号
    NSMutableString *stamp = dict[@"timestamp"];
    //调起微信支付
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = dict[@"partnerid"];
    req.prepayId = dict[@"prepayid"];
    req.nonceStr = dict[@"noncestr"];
    req.timeStamp = stamp.intValue;
    req.package = @"Sign=WXPay";
    req.sign = dict[@"sign"];
    [WXApi sendReq:req];
}

- (void)responderOfInvokingIAPPaymentWithProductIdentifier:(NSString *)productIdentifier
{
    if (self.iAPobject.canMakePayments)
    {
        [self.iAPobject getProductInfo:productIdentifier];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(managerDidResponsePayResult:platform:)])
        {
            NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObject:@"用户禁止应用内付费购买" forKey:@"memo"];
            [self.delegate managerDidResponsePayResult:result platform:PayPlatformOfAppPay];
        }
    }
}

#pragma mark - <微信支付回调>
//微信支付结果回调
- (void)managerDidRecvPayResultResponse:(int)errCode withErrorString:(NSString *)errorString andReturnKey:(NSString *)returnKey
{
    //支付返回结果，实际支付结果需要去微信服务器端查询
    NSString *memo = nil;
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    switch (errCode)
    {
        case WXSuccess:
            memo = @"支付成功!";
            break;
        case WXErrCodeUserCancel://用户取消
            memo = @"支付已取消!";
            break;
        case WXErrCodeSentFail://发送失败
            memo = @"发起支付失败!";
            break;
        case WXErrCodeAuthDeny:   //授权失败
            memo = @"支付授权失败!";
            break;
        case WXErrCodeUnsupport:   //微信不支持
            memo = @"您的微信不支持该类支付!";
            break;
        default:
            memo = [NSString stringWithFormat:@"微信支付失败！错误码: %d, 错误信息: %@", errCode, errorString];
            break;
    }
    //回调信息
    [result setValue:self.wxOutTradeNo forKey:@"outTradeNo"];
    [result setValue:memo forKey:@"memo"];
    //代理回调
    if (self.delegate && [self.delegate respondsToSelector:@selector(managerDidResponsePayResult:platform:)])
    {
        [self.delegate managerDidResponsePayResult:result platform:PayPlatformOfWechat];
    }
}

#pragma mark - <IAP支付回调>
- (void)transactionDidResponseState:(NSString *)msg
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObject:msg forKey:@"memo"];
    [self.delegate managerDidResponsePayResult:result platform:PayPlatformOfAppPay];
}

@end
