//
//  YNVoicePlayM.h
//  Messenger
//
//  Created by 黄旭 on 2020/6/22.
//  Copyright © 2020 YN-APP-iOS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YNVoicePlayM : NSObject
// 曲目url
@property (nonatomic, copy) NSString *urlStr;
// 曲目歌手
@property (nonatomic, copy) NSString *artist;
// 曲目名称
@property (nonatomic, copy) NSString *title;
@end

NS_ASSUME_NONNULL_END
