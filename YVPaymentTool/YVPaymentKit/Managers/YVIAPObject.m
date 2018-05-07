//
//  YVIAPObject.m
//  YVPaymentTool
//
//  Created by 周荣飞 on 2018/5/5.
//  Copyright © 2018年 YoonveyTest. All rights reserved.
//

#import "YVIAPObject.h"

#import "GTMBase64.h"

@implementation YVIAPObject

#pragma mark - <LifeCycle>
- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

//是否允许购买
- (BOOL)canMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

#pragma mark - <查询商品>
//获取商品信息
- (void)getProductInfo:(NSString *)productIdentifier
{
    NSArray *productIdentifiers = [[NSArray array] initWithObjects:productIdentifier, nil];
    NSSet *set = [NSSet setWithArray:productIdentifiers];
    SKProductsRequest *requet = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    requet.delegate = self;
    [requet start];
    NSLog(@"获取商品信息...");
}

#pragma mark - <商品信息查询回调>
//查询到商品后回调
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *resProducts = response.products;
    if (resProducts.count != 0)
    {
        SKPayment *payment = [SKPayment paymentWithProduct:resProducts[0]];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else
    {
        NSLog(@"无法获取产品信息，请重试!");
    }
}

//查询失败后的回调
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"获取产品信息失败,请重试!");
}

#pragma mark - <购买操作后的回调>
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transation in transactions)
    {
        switch (transation.transactionState)
        {
            case SKPaymentTransactionStatePurchasing://商品添加进列表
                NSLog(@"正在请求付费信息");
                break;
            case SKPaymentTransactionStatePurchased://交易完成
            {
                NSString *receiptStr = [GTMBase64 stringByEncodingData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
                [self setValue:receiptStr forKey:NSStringFromSelector(@selector(receipt))];
                [self transactionDidComplete:transation];
            }
                break;
            case SKPaymentTransactionStateFailed://交易失败
                [self transactionDidFailed:transation];
                break;
            case SKPaymentTransactionStateRestored://交易重复
                [self transactionDidRestore:transation];
                break;
            
            default:
                break;
        }
    }
}

//交易结束
- (void)transactionDidComplete:(SKPaymentTransaction *)transaction
{
    //代理回调
    if (self.delegate && [self.delegate respondsToSelector:@selector(transactionDidResponseState:)])
    {
        [self.delegate transactionDidResponseState:@"交易完成!"];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

//交易失败
- (void)transactionDidFailed:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        //代理回调
        if (self.delegate && [self.delegate respondsToSelector:@selector(transactionDidResponseState:)])
        {
            [self.delegate transactionDidResponseState:@"购买失败,请重试!"];
        }
    }
    else
    {
        //代理回调
        if (self.delegate && [self.delegate respondsToSelector:@selector(transactionDidResponseState:)])
        {
            [self.delegate transactionDidResponseState:@"用户取消交易!"];
        }
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

//交易重复
- (void)transactionDidRestore:(SKPaymentTransaction *)transaction
{
    //代理回调
    if (self.delegate && [self.delegate respondsToSelector:@selector(transactionDidResponseState:)])
    {
        [self.delegate transactionDidResponseState:@"交易重复!"];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}



@end
