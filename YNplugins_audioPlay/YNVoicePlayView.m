//
//  YNVideoPlayPlayerV.m
//  Messenger
//
//  Created by 黄旭 on 2020/6/12.
//  Copyright © 2020 YN-APP-iOS. All rights reserved.
//

#import "YNVoicePlayView.h"
#import "YNVoicePlayTool.h"
#import <AVFoundation/AVFoundation.h>

@interface YNVoicePlayView ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) id timeObserver;
@property (weak, nonatomic) IBOutlet UIView *backMainView;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (strong, nonatomic) YNVoicePlayM * playModel;
@property (assign, nonatomic) BOOL playCompleted;
//是否播放失败
@property (assign, nonatomic) BOOL playDefeated;
//是否已经可以播放
@property (assign, nonatomic) BOOL playAble;
//是否正在播放-控制当应用处于活跃或不活跃状态时的播放
@property (assign, nonatomic) BOOL isPlaying;
@end

@implementation YNVoicePlayView

// 从文件中加载控件时调用
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.progressSlider.value = 0.f;
    }
    return self;
}

// xib加载完毕调用
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.progressSlider setThumbImage:[UIImage imageNamed:BundleSource(@"voiceplaySliderImage.png")] forState:UIControlStateNormal];
    [self.progressSlider setThumbImage:[UIImage imageNamed:BundleSource(@"voiceplaySliderImage.png")] forState:UIControlStateHighlighted];
    [self.progressSlider setThumbImage:[UIImage imageNamed:BundleSource(@"voiceplaySliderImage.png")] forState:UIControlStateSelected];
    [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voiceplayImage.png")] forState:UIControlStateNormal];
    self.progressSlider.value = .0f;
    self.totalTimeLabel.text = @"00:00";
    [self.progressSlider addTarget:self action:@selector(progressDragEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    self.backMainView.layer.cornerRadius=10;
    self.backMainView.layer.masksToBounds=YES;
    self.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    UITapGestureRecognizer*tapp=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(removeView)];
    UITapGestureRecognizer*voidTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(voidTapSelector)];
    [self.backMainView addGestureRecognizer:voidTap];
    [self addGestureRecognizer:tapp];
    self.alpha=0.f;
    [UIView animateWithDuration:.5f animations:^{
        self.alpha=1.f;
    }];
    
}
-(void)voidTapSelector{
    
}
- (void)playWithPlayInfo:(YNVoicePlayM *)playInfo
{
    self.playModel=playInfo;
    // 重置player
    [self resetPlayer];
    
    //配置在静音模式下也能播放声音
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    self.asset = [AVURLAsset assetWithURL:[NSURL URLWithString:playInfo.urlStr]];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    // 添加时间周期OB、OB和通知
    [self addTimerObserver];
    [self addPlayItemObserverAndNotification];
    
//    [self.waitingView startAnimating];
    
    // 刚开始切换视频时 rate为0时显示视频海报(placeholder)
    if (self.player.rate > 0) {
//        [self.waitingView stopAnimating];
    } else {
//        [self.waitingView startAnimating];
    }
    [self.player play];
    self.isPlaying=YES;
}
// 重置播放器
- (void)resetPlayer
{
    [self removePlayItemObserverAndNotification];
    [self removeTimeObserver];
    self.playCompleted=NO;
    self.playDefeated=NO;
    self.playAble=NO;
    self.isPlaying=NO;
    if (self.player) {
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
        self.asset = nil;
        self.playerItem = nil;
        self.player = nil;
    }
}

// 给playItem添加观察者KVO
- (void)addPlayItemObserverAndNotification
{
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:NULL];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFailed:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    //应用程序状态监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIApplicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApplicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

// 移除观察者和通知
- (void)removePlayItemObserverAndNotification
{
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// 给进度条Slider添加时间OB
- (void)addTimerObserver
{
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        weakSelf.totalTimeLabel.text=[YNVoicePlayTool displayPlayTime:CMTimeGetSeconds(weakSelf.asset.duration)-CMTimeGetSeconds(weakSelf.player.currentTime)];
        weakSelf.progressSlider.value = CMTimeGetSeconds(weakSelf.player.currentTime);
        if (CMTimeGetSeconds(weakSelf.asset.duration) <= CMTimeGetSeconds(weakSelf.player.currentTime)) {
            weakSelf.totalTimeLabel.text=@"00:00";
        }
    }];
}

// 移除时间OB
- (void)removeTimeObserver
{
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}
// 播放或暂停
- (void)playOrPause
{
    if (self.playDefeated) {
        [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voiceplayImage.png")] forState:UIControlStateNormal];
        [self retryPlay];
    }else{
        if (self.playCompleted) {
            [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voicepauseImage.png")] forState:UIControlStateNormal];
            [self replay];
        }else{
            if (self.player.timeControlStatus == AVPlayerTimeControlStatusPaused) {
                [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voicepauseImage.png")] forState:UIControlStateNormal];
                [self.player play];
                self.isPlaying=YES;
            } else if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
                [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voiceplayImage.png")] forState:UIControlStateNormal];
                [self.player pause];
                self.isPlaying=NO;
            }
        }
    }
    
}
//程序进入前台活动状态
-(void)UIApplicationDidBecomeActive{
    if (self.isPlaying) {
        [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voicepauseImage.png")] forState:UIControlStateNormal];
        [self.player play];
    }
}
//程序进入后台状态
-(void)ApplicationWillResignActive{
    [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voiceplayImage.png")] forState:UIControlStateNormal];
    [self.player pause];
}
//播放完成回调
- (void)playFinished:(NSNotification *)note {
    self.playCompleted=YES;
    self.isPlaying=NO;
    [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voiceplayImage.png")] forState:UIControlStateNormal];
}
//播放失败回调
-(void)playFailed:(NSNotification *)note{
    debugLog(@"播放错误的信息：%@",self.player.error.description);
//    [self.waitingView stopAnimating];
    [YNVoicePlayTool HUDReminderOfSimpleWithString:@"音频加载失败或网络异常"];
    [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voiceplayImage.png")] forState:UIControlStateNormal];
    self.playDefeated=YES;
    self.playAble=NO;
    self.isPlaying=NO;
}
// 播放完后重播
- (void)replay
{
    self.playCompleted=NO;
    self.progressSlider.value=0.f;
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
    self.isPlaying=YES;
}
//播放失败，重试播放
-(void)retryPlay{
    self.playDefeated=NO;
    self.progressSlider.value=0.f;
    [self playWithPlayInfo:self.playModel];
}
// KVO检测播放器各种状态
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) { // 检测播放器状态
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        if (status == AVPlayerStatusReadyToPlay) { // 达到能播放的状态
//            [self.waitingView stopAnimating];
            NSTimeInterval totalTime = CMTimeGetSeconds(self.asset.duration);
            self.totalTimeLabel.text = [YNVoicePlayTool displayPlayTime:totalTime];
            self.progressSlider.maximumValue = totalTime;
            [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voicepauseImage.png")] forState:UIControlStateNormal];
            self.playDefeated=NO;
            self.playAble=YES;
        } else if (status == AVPlayerStatusFailed) { // 播放错误 资源不存在 网络问题等等
            [self playFailed:nil];
        } else if (status == AVPlayerStatusUnknown) { // 未知错误
            [self playFailed:nil];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) { // 检测缓存状态
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {  // 缓存为空
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) { // 缓存足够能播放
    }
}

- (void)removeView{
    [UIView animateWithDuration:.5f animations:^{
        self.alpha=0.f;
    } completion:^(BOOL finished) {
        [self resetPlayer];
        [self removeFromSuperview];
        if (self.backPageBlock) {
            self.backPageBlock();
        }
    }];
}

// 播放或暂停按钮点击
- (IBAction)playOrPauseAction
{
    [self playOrPause];
}
// 拖拽进度条
- (IBAction)dragProgressAction:(UISlider *)sender {
    if (self.playDefeated||self.playAble==NO) {
        return;
    }
    [self removeTimeObserver];
    self.totalTimeLabel.text = [YNVoicePlayTool displayPlayTime:CMTimeGetSeconds(self.asset.duration)-sender.value];
}

// 进度条拖拽结束
- (void)progressDragEnd:(UISlider *)sender
{
    [self.player seekToTime:CMTimeMake(self.progressSlider.value, 1.0)];
    [self.playBtn setImage:[UIImage imageNamed:BundleSource(@"voicepauseImage.png")] forState:UIControlStateNormal];
    [self.player play];
    self.isPlaying=YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addTimerObserver];
    });
}

- (void)dealloc
{
    [self removePlayItemObserverAndNotification];
    [self removeTimeObserver];
    debugLog(@"音频播放核心组件释放了");
}
@end
