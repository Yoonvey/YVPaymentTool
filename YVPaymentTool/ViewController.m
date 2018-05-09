//
//  ViewController.m
//  YVPaymentTool
//
//  Created by 周荣飞 on 2018/5/5.
//  Copyright © 2018年 YoonveyTest. All rights reserved.
//

#import "ViewController.h"

#import "YVPaymentManager.h"

@interface ViewController () <YVPaymentDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - <实现支付代理协议>
//返回授权回调信息
- (void)managerDidResponseAuthResult:(NSDictionary *)resultDic platform:(PayPlatform)platform
{
    
}

//返回支付回调信息
- (void)managerDidResponsePayResult:(NSDictionary *)resultDic platform:(PayPlatform)platform
{
    switch (platform)
    {
        case PayPlatformOfWechat:
            
            break;
        case PayPlatformOfAlipay:
            
            break;
        case PayPlatformOfAppPay:
            
            break;
        case PayPlatformOfCustom:
            
            break;
        default:
            break;
    }
}


@end
