//
//  YNVoicePlayView.h
//  Messenger
//
//  Created by 黄旭 on 2020/6/22.
//  Copyright © 2020 YN-APP-iOS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YNVoicePlayM.h"

NS_ASSUME_NONNULL_BEGIN

@interface YNVoicePlayView : UIView
@property(nonatomic,copy)void(^backPageBlock)(void);

- (void)playWithPlayInfo:(YNVoicePlayM *)playInfo;
@end

NS_ASSUME_NONNULL_END
