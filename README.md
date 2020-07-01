# YNplugins_audioPlay
音频播放通用插件xx

这是一个framework包的源码开发项目，使用时需要先自己合成framework包然后导入项目使用，使用时注意，在Build Phases里需要在Link Binary With Libraries和Copy Bundle Resources里分别添加这个framework
,将YNplugins_audioPlaySource.bundle也要导入项目中，才能正常使用。调用的示例代码为

YNVoicePlayView*voiceV=[[[NSBundle bundleWithPath:[[NSBundle mainBundle]pathForResource:@"YNplugins_audioPlay" ofType:@"framework"]] loadNibNamed:@"YNVoicePlayView" owner:nil options:nil] lastObject];
[[UIApplication sharedApplication].keyWindow addSubview:voiceV];
[voiceV mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo([UIApplication sharedApplication].keyWindow);
}];
YNVoicePlayM *playInfo = [[YNVoicePlayM alloc]init]; playInfo.urlStr=argDic[@"url"];
[voiceV playWithPlayInfo:playInfo];
voiceV.backPageBlock = ^{
};
