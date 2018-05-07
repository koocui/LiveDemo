//
//  PlcBroadcastRoomViewController.m
//  LiveDemo
//
//  Created by 小崔 on 2018/5/4.
//  Copyright © 2018年 CJW. All rights reserved.
//

#import "PlcBroadcastRoomViewController.h"
#import <PLCameraStreamingKit/PLCameraStreamingKit.h>

#define kHost @"http://192.168.200.127:8080"

@interface PlcBroadcastRoomViewController ()
@property (nonatomic,strong) PLCameraStreamingSession * cameraStreamingSession;
@property (nonatomic,strong) NSString * roomID;
@end

@implementation PlcBroadcastRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cameraStreamingSession = [self _generateCameraStreamingSession];
    
    [self requireDevicePermissionWithComplete:^(BOOL granted) {
        if (granted){
            [self.view addSubview:({
                UIView * preview = self.cameraStreamingSession.previewView;
                preview.frame = self.view.bounds;
                preview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                preview;
            })];
        }
    }];
    
    
    __weak typeof(self) weakSelf = self;
    [self _generatePushURLWithComplete:^(PLStream *stream) {
        __strong typeof(self) strongSelf = weakSelf;
        //当收到pushURL 时，viewController 可能已经提前关闭和销毁，此时不可进行推流
        if (strongSelf){
            strongSelf.cameraStreamingSession.stream = stream;
            [strongSelf.cameraStreamingSession startWithCompleted:^(BOOL success) {
                if (!success){
                    NSLog(@"推流失败");
                }
            }];
        }
    }];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.cameraStreamingSession destroy];//结束推流
    [self _notifyServerExitRoom];
}
//通知服务器结束直播
-(void)_notifyServerExitRoom{
    if (self.roomID){
        NSString * url = [NSString stringWithFormat:@"%@%@%@",kHost,@"/api/pilipili/",self.roomID];
        NSMutableURLRequest * request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:url]];
        request.HTTPMethod = @"DELETE";
        request.timeoutInterval = 10;
        [[[NSURLSession sharedSession]dataTaskWithRequest:request]resume];
    }
}
//获取相机和麦克风的权限
-(void)requireDevicePermissionWithComplete:(void (^)(BOOL granted))complete{
    switch ([PLCameraStreamingSession cameraAuthorizationStatus]) {
        case PLAuthorizationStatusAuthorized:
            complete(YES);
            break;
        case PLAuthorizationStatusNotDetermined:{
            [PLCameraStreamingSession requestCameraAccessWithCompletionHandler:^(BOOL granted) {
                complete(granted);
            }];
        }
            complete(YES);
            break;
        default:
            complete(NO);
            break;
    }
}

//获取推流地址的逻辑
-(void)_generatePushURLWithComplete:(void (^)(PLStream * stream))complete{
    NSString * url = [NSString stringWithFormat:@"%@%@",kHost,@"/api/pilipili"];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 10;
    [request setHTTPBody:[@"title=room" dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask * task = [[NSURLSession sharedSession]dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError * error1 = error;
            if (error1 !=nil || response ==nil || data == nil ){
                return;
            }
            NSDictionary * streamJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error1];
            self.roomID = streamJSON[@"id"];
            PLStream * strem = [PLStream streamWithJSON:streamJSON];
            if (complete){
                complete(strem);
            }
            
        });
    }];
    [task resume];
}

//初始化；
-(PLCameraStreamingSession *)_generateCameraStreamingSession{
    //视频采集配置，对应的是摄像头；
    PLVideoCaptureConfiguration * videoCaptureConfiguration;
    //视频推流配置，对应的是推流出去的画面；
    PLVideoStreamingConfiguration * videoStreamingConfiguration;
    //音频采集配置，对应的是麦克风。
    PLAudioCaptureConfiguration * audioCaptureConfiguration;
    //音频推理配置，对应的是推流出去的声音。
    PLAudioStreamingConfiguration * audioStreamingConfiguration;
    
    videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
    videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
    audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
    audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
    
    AVCaptureVideoOrientation captureOrientation = AVCaptureVideoOrientationPortrait;
    
    PLStream * stream = nil;
    return [[PLCameraStreamingSession alloc]initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:stream videoOrientation:captureOrientation];
    
    
}

@end

























