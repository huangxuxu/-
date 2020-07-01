//
//  YNVoicePlayTool.m
//  YNplugins_audioPlay
//
//  Created by 黄旭 on 2020/6/30.
//  Copyright © 2020 huangxu. All rights reserved.
//

#import "YNVoicePlayTool.h"
//HUD显示的视图
#define HUDSuperViewOfShow [UIApplication sharedApplication].keyWindow
//HUD消失的默认时长
static CGFloat HUDHideDelayTime = 2.0f;

@implementation YNVoicePlayTool
+(NSString*)displayPlayTime:(NSTimeInterval)time{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
    
    if (time >= 3600) {
        [dateFmt setDateFormat:@"HH:mm:ss"];
    } else {
        [dateFmt setDateFormat:@"mm:ss"];
    }
    return [dateFmt stringFromDate:date];
}
//HUD简单提示输出
+(MBProgressHUD*)HUDReminderOfSimpleWithString:(NSString*)infoString{
    __block MBProgressHUD *hud=nil;
    if (![NSThread isMainThread]) {
        dispatch_semaphore_t createTableSemaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self HUDhideAll];
            hud = [MBProgressHUD showHUDAddedTo:HUDSuperViewOfShow animated:YES];
            hud.removeFromSuperViewOnHide = YES;
            hud.mode = MBProgressHUDModeText;
            hud.detailsLabel.text= infoString;
            hud.detailsLabel.font = [UIFont systemFontOfSize:16];
            hud.margin = 10.f;
            [hud hideAnimated:YES afterDelay:HUDHideDelayTime];
            dispatch_semaphore_signal(createTableSemaphore);
        });
        dispatch_semaphore_wait(createTableSemaphore, DISPATCH_TIME_FOREVER);
    }else{
        [self HUDhideAll];
        hud = [MBProgressHUD showHUDAddedTo:HUDSuperViewOfShow animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.mode = MBProgressHUDModeText;
        hud.detailsLabel.text= infoString;
        hud.detailsLabel.font = [UIFont systemFontOfSize:16];
        hud.margin = 10.f;
        [hud hideAnimated:YES afterDelay:HUDHideDelayTime];
    }
    return hud;
}
//隐藏所有HUD
+(void)HUDhideAll{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:HUDSuperViewOfShow animated:YES];
        });
    }else{
        [MBProgressHUD hideAllHUDsForView:HUDSuperViewOfShow animated:YES];
    }
}
@end
