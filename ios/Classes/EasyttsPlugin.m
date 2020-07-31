#import "EasyttsPlugin.h"
#if __has_include(<easytts/easytts-Swift.h>)
#import <easytts/easytts-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "easytts-Swift.h"
#endif

@implementation EasyttsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"easytts" binaryMessenger:[registrar messenger]];
    EasyttsPlugin * instance = [[EasyttsPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    self.speechSynthesizer.delegate = self;
   // self.speechSynthesizer.delegate = self;
    self.rate = (AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate) * 0.5;

    [[NSNotificationCenter defaultCenter]
          addObserver:self
             selector:@selector(audioRouteChangeListenerCallback:)
                 name:AVAudioSessionRouteChangeNotification
               object:[AVAudioSession sharedInstance]];
    return self;
}

/**
 *  监听耳机插入拔出状态的改变
 *  @param notification 通知
 */
- (void)audioRouteChangeListenerCallback:(NSNotification *)notification {
      NSDictionary *interuptionDict = notification.userInfo;
      NSInteger routeChangeReason   = [[interuptionDict
          valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
      switch (routeChangeReason) {
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
                  [self pause];
                  break;
      }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"speak" isEqualToString:call.method]) {
        [self speak:call.arguments[@"text"]];
    } else if ([@"pause" isEqualToString:call.method]) {
        [self pause];
    } else if ([@"resume" isEqualToString:call.method]) {
        [self resume];
    } else if ([@"stop" isEqualToString:call.method]) {
        [self stop];
    } else if ([@"setSpeechRate" isEqualToString:call.method]) {
        NSString *rate = call.arguments[@"rate"];
        [self setSpeechRate:rate.floatValue];
    } else if ([@"shutdown" isEqualToString:call.method]) {
        [self shutdown];
    } else if ([@"isLanguageAvailable" isEqualToString:call.method]) {
        BOOL isAvailable = [self isLanguageAvailable:call.arguments[@"language"]];
        result(@(isAvailable));
    } else if ([@"setLanguage" isEqualToString:call.method]) {
        BOOL success = [self setLanguage:call.arguments[@"language"]];
        result(@(success));
    } else if ([@"getAvailableLanguages" isEqualToString:call.method]) {
        result([self getLanguages]);
    } else if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (BOOL) isLanguageAvailable:(NSString*) locale {
    NSArray<AVSpeechSynthesisVoice*> *voices = [AVSpeechSynthesisVoice speechVoices];
    for (AVSpeechSynthesisVoice* voice in voices) {
        if([voice.language isEqualToString:locale])
            return YES;
    }
    return NO;
}

-(BOOL)setSpeechRate:(float)rate {
    CGFloat range = AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate;
    self.rate = AVSpeechUtteranceMinimumSpeechRate + rate * range;
    return YES;
}

-(BOOL) setLanguage:(NSString*) locale {
    if([self isLanguageAvailable:locale]){
        self.locale = locale;
        return YES;
    }
    return NO;
}

-(NSArray*) getLanguages {
    NSMutableArray* languages = [[NSMutableArray alloc] init];
    for (AVSpeechSynthesisVoice* voice in [AVSpeechSynthesisVoice speechVoices]) {
        [languages addObject:voice.language];
    }
    NSArray *arr = [languages copy];
    return arr;
    
}

-(void)speak:(NSString*) text {
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:text];
    utterance.rate = self.rate;
    if(self.locale != nil){
        AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.locale];
        utterance.voice = voice;
    }
    [self.speechSynthesizer speakUtterance:utterance];
}

-(void)pause {
    [self.speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

-(void)resume {
    [self.speechSynthesizer continueSpeaking];
}

-(void)stop {
    [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

-(void)shutdown {
    if (self.speechSynthesizer != nil) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    [self.channel invokeMethod:@"onComplete" arguments:nil];
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    [self.channel invokeMethod:@"onCancel" arguments:nil];
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    [self.channel invokeMethod:@"onPause" arguments:nil];
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    [self.channel invokeMethod:@"onSpeak" arguments:nil];
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    [self.channel invokeMethod:@"onResume" arguments:nil];
}

-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
    [self.channel invokeMethod:@"onWill" arguments:@{
        @"index": @(characterRange.location),
        @"length": @(characterRange.length)
    }];
}
@end
