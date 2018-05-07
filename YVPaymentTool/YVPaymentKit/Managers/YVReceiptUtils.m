//
//  YVReceiptUtils.m
//  YVPaymentTool
//
//  Created by 周荣飞 on 2018/5/5.
//  Copyright © 2018年 YoonveyTest. All rights reserved.
//

#import "YVReceiptUtils.h"

#define AppStoreInfoLocalFilePath [NSString stringWithFormat:@"%@/%@/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],@"Receipt"]

@implementation YVReceiptUtils

//持久化存储用户购买凭证(这里最好还要存储当前日期，用户id等信息，用于区分不同的凭证)
+ (BOOL)saveReceipt:(NSString *)receipt forUser:(NSString *)userId
{
    NSString *fileName = [self getUUIDString];
    NSString *savedPath = [NSString stringWithFormat:@"%@%@.plist", AppStoreInfoLocalFilePath, fileName];
    NSDictionary *dic = [ NSDictionary dictionaryWithObjectsAndKeys:receipt,@"receipt", [NSDate date],@"date", userId,@"userId", nil];
    return [dic writeToFile:savedPath atomically:YES];
}

+ (BOOL)recheckReceiptIsValid
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //从服务器验证receipt失败之后，在程序再次启动的时候，使用保存的receipt再次到服务器验证
    if (![fileManager fileExistsAtPath:AppStoreInfoLocalFilePath])//如果在改路下不存在文件，说明就没有保存验证失败后的购买凭证，也就是说发送凭证成功。
    {
        [fileManager createDirectoryAtPath:AppStoreInfoLocalFilePath//创建目录
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
        return NO;
    }
    else//存在购买凭证，说明发送凭证失败，再次发起验证
    {
        return YES;
    }
}

//验证receipt失败,App启动后再次验证
+ (NSString *)getFailedIAPFilePath
{
    if([self recheckReceiptIsValid])
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        //搜索该目录下的所有文件和目录
        NSArray *cacheFileNameArray = [fileManager contentsOfDirectoryAtPath:AppStoreInfoLocalFilePath error:&error];
        if (error == nil)
        {
            for (NSString *name in cacheFileNameArray)
            {
                if ([name hasSuffix:@".plist"])//如果有plist后缀的文件，说明就是存储的购买凭证
                {
                    NSString *filePath = [NSString stringWithFormat:@"%@/%@", AppStoreInfoLocalFilePath, name];
                    return filePath;
                }
            }
        }
        else
        {
            NSLog(@"AppStoreInfoLocalFilePath error:%@", [error domain]);
            return nil;
        }
    }
    return nil;
}

+ (BOOL)removeReceiptFilePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:AppStoreInfoLocalFilePath])
    {
        return [fileManager removeItemAtPath:AppStoreInfoLocalFilePath error:nil];
    }
    return NO;
}

//每次调用该方法都生成一个新的UUID
+ (NSString *)getUUIDString
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault , uuidRef);
    NSString *uuidString = [(__bridge NSString*)strRef stringByReplacingOccurrencesOfString:@"-" withString:@""];
    CFRelease(strRef);
    CFRelease(uuidRef);
    return uuidString;
}

@end
