#import <Flutter/Flutter.h>
@import AVFoundation;

@interface EasyttsPlugin : NSObject<FlutterPlugin, AVSpeechSynthesizerDelegate>
@property (readwrite, nonatomic, strong) FlutterMethodChannel *channel;
@property (readwrite, nonatomic, strong) AVSpeechSynthesizer *speechSynthesizer;
@property (strong) NSString *locale;
@property (assign) float rate;
@end
