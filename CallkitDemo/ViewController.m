//
//  ViewController.m
//  CallkitDemo
//

#import "ViewController.h"
#import <CallKit/CallKit.h>
#import <AVKit/AVKit.h>

@interface ViewController ()<CXProviderDelegate>

@property(nonatomic, strong) CXProvider *provider;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"CallKit Demo"];
    configuration.maximumCallGroups = 1;
    configuration.maximumCallsPerCallGroup = 1;
    configuration.includesCallsInRecents = NO;
    configuration.supportsVideo = NO;
    configuration.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypePhoneNumber)];
    _provider = [[CXProvider alloc] initWithConfiguration:configuration];
    [_provider setDelegate:self queue:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRouterChange:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
}

- (void)reportIncomingCall {
    /// Refer to : https://developer.apple.com/forums/thread/64544
    /// TODO: Change this method
    [self configAudioSession1];
    NSUUID *uuid = [NSUUID UUID];
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:@"17192662837"];
    update.localizedCallerName = @"caller nickname";
    update.supportsHolding = NO;
    update.supportsDTMF = NO;
    update.hasVideo = NO;
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        if (error) NSLog(@"reportNewIncomingCallWithUUID error: %@", error);
    }];
}

/// Config audio session using `setCategory:mode:options:error:`
/// 1. CallKit speaker button does not work unless `AVAudioSessionCategoryOptionAllowBluetoothA2DP` is included in the options
/// 2. Options set success
- (void)configAudioSession1 {
    NSLog(@"Using configAudioSession1");
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    AVAudioSessionCategory category = AVAudioSessionCategoryPlayAndRecord;
    NSUInteger options = AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionMixWithOthers;

    [session setCategory:category mode:AVAudioSessionModeVoiceChat options:options error:&error];
    if (error) NSLog(@"setCategory error: %@", error);
    if (session.categoryOptions != options) {
        NSLog(@"Failed setting options: %lu", session.categoryOptions);
    } else {
        NSLog(@"Success setting options: %lu", session.categoryOptions);
    }
    error = nil;
    [session setActive:YES error:&error];
    if (error) NSLog(@"setActive error: %@", error);
}

/// Config audio session using `setCategory:withOptions:error:` and `setMode:error:`
/// 1. CallKit speaker button works well
/// 2. Options set failed，`AVAudioSessionCategoryOptionAllowBluetooth` is invalid
- (void)configAudioSession2 {
    NSLog(@"Using configAudioSession2");
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    AVAudioSessionCategory category = AVAudioSessionCategoryPlayAndRecord;
    NSUInteger options = AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionMixWithOthers;

    [session setCategory:category withOptions:options error:&error];
    if (error) NSLog(@"setCategory error: %@", error);
    error = nil;
    [session setMode:AVAudioSessionModeVoiceChat error:&error];
    if (error) NSLog(@"setMode error: %@", error);
    if (session.categoryOptions != options) {
        NSLog(@"Failed setting options: %lu", session.categoryOptions);
    } else {
        NSLog(@"Success setting options: %lu", session.categoryOptions);
    }
    error = nil;
    [session setActive:YES error:&error];
    if (error) NSLog(@"setActive error: %@", error);
}

/// Config audio session use `setCategory:withOptions:error:` and `setMode:error:` and set option again
/// 1. CallKit speaker button does not work
/// 2. Options set success
- (void)configAudioSession3 {
    NSLog(@"Using configAudioSession3");
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    AVAudioSessionCategory category = AVAudioSessionCategoryPlayAndRecord;
    NSUInteger options = AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionMixWithOthers;

    [session setCategory:category withOptions:options error:&error];
    if (error) NSLog(@"setCategory error: %@", error);
    error = nil;
    [session setMode:AVAudioSessionModeVoiceChat error:&error];
    if (error) NSLog(@"setMode error: %@", error);
    if (session.categoryOptions != options) {
        /// Set options again
        NSError *error = nil;
        [session setCategory:category withOptions:options error:&error];
        if (error) NSLog(@"Second attempt to setCategory failed with error: %@", error);
    }
    if (session.categoryOptions != options) {
        NSLog(@"Failed setting options: %lu", session.categoryOptions);
    } else {
        NSLog(@"Success setting options: %lu", session.categoryOptions);
    }
    error = nil;
    [session setActive:YES error:&error];
    if (error) NSLog(@"setActive error: %@", error);
}

- (IBAction)testCall:(id)sender {
    [self reportIncomingCall];
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider {

}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    [action fulfill];
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"didActivateAudioSession");
    NSLog(@"category: %@ options: %lu mode: %@", audioSession.category, (unsigned long)audioSession.categoryOptions, audioSession.mode);
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"didDeactivateAudioSession");
}

#pragma mark - notify

- (void)handleRouterChange:(NSNotification *)notify {
    NSDictionary *userInfo = notify.userInfo;
    AVAudioSession *session = notify.object;
    AVAudioSessionRouteDescription* previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey];
    AVAudioSessionRouteDescription* currentRoute = session.currentRoute;
    AVAudioSessionPort oldOutputPort = previousRoute.outputs.firstObject.portType;
    AVAudioSessionPort newOutput = currentRoute.outputs.firstObject.portType;
    NSLog(@"oldOutput:%@  newOutput:%@", oldOutputPort, newOutput);
}

@end
