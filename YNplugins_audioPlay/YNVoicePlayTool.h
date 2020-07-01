//
//  YNVoicePlayTool.h
//  YNplugins_audioPlay
//
//  Created by 黄旭 on 2020/6/30.
//  Copyright © 2020 huangxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

NS_ASSUME_NONNULL_BEGIN

@interface YNVoicePlayTool : NSObject
//播放时间格式处理
+(NSString*)displayPlayTime:(NSTimeInterval)time;
//HUD简单屏中间提示
+(MBProgressHUD*)HUDReminderOfSimpleWithString:(NSString*)infoString;
@end

#ifdef DEBUG
#define debugLog(...) NSLog(__VA_ARGS__)
#define debugMethod() NSLog(@"%s", __func__)
#else
#define debugLog(...)
#define debugMethod()
#endif

#define BundleSource(_name) [NSString stringWithFormat:@"YNplugins_audioPlaySource.bundle/%@",_name]

NS_ASSUME_NONNULL_END
