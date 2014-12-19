//
//  ViewController.m
//  MergeVideoDemo
//
//  Created by Kevin on 14/12/18.
//  Copyright (c) 2014年 HGG. All rights reserved.
//

#import "ViewController.h"
#import <SVProgressHUD.h>
@import AVFoundation;
@import MobileCoreServices;
@import AssetsLibrary;

@interface ViewController ()
<
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIAlertViewDelegate
>

@property (nonatomic, strong) NSURL *videoURL;
/** 来自相册或者摄像头拍摄的视频 */
@property (nonatomic, strong) AVURLAsset *firstAsset;
/** 已存在沙箱中的视频 */
@property (nonatomic, strong) AVURLAsset *secondAsset;
@property (nonatomic, strong) AVMutableVideoComposition *mainComposition;
@property (nonatomic, strong) AVMutableComposition *mixComposition;
@property (nonatomic, strong) UIImagePickerController *picker;

- (IBAction)loadingVideoClick:(UIButton *)sender;
- (IBAction)mergeVideoClick:(UIButton *)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Property

- (UIImagePickerController *)picker
{
    if (!_picker) {
        _picker = [[UIImagePickerController alloc] init];
        _picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
        _picker.allowsEditing = YES;
        _picker.delegate = self;
    }
    return _picker;
}

- (AVMutableComposition *)mixComposition
{
    if (!_mixComposition) {
        _mixComposition = [[AVMutableComposition alloc] init];
    }
    return _mixComposition;
}

#pragma mark - User Action

- (IBAction)loadingVideoClick:(UIButton *)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"hello" message:@"视频从相册选择还是自拍？" delegate:self cancelButtonTitle:@"相册" otherButtonTitles:@"自拍", nil];
    [alert show];
}

- (IBAction)mergeVideoClick:(UIButton *)sender
{
    /**
     合成视频套路就是下面几条，跟着走就行了，具体函数意思自行google
     1.不用说，肯定加载。用ASSET
     2.这里不考虑音轨，所以只获取video信息。用track 获取asset里的视频信息，一共两个track,一个track是你自己拍的视频，第二个track是特效视频,因为两个视频需要同时播放，所以起始时间相同，都是timezero,时长自然是你自己拍的视频时长。然后把两个track都放到mixComposition里。
     3.第三步就是最重要的了。instructionLayer,看字面意思也能看个七七八八了。架构图层，就是告诉系统，等下合成视频，视频大小，方向，等等。这个地方就是合成视频的核心。我们只需要更改透明度就行了，把特效track的透明度改一下，让他能显示底下你自己拍的视屏图层就行了。
     */
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    if (self.videoURL) {
        
        self.firstAsset = [AVAsset assetWithURL:self.videoURL];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"dry" ofType:@"mp4"];
        NSLog(@"path is %@",path);
        self.firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];

        self.secondAsset = [AVURLAsset URLAssetWithURL:self.videoURL options:nil];
        NSLog(@"second Asset = %@",self.secondAsset);
    } else {
        [SVProgressHUD showErrorWithStatus:@"选择视频" maskType:SVProgressHUDMaskTypeBlack];
    }
    
    if (self.firstAsset && self.secondAsset) {
        AVMutableCompositionTrack *firstTrack = [self.mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *firstOfTrack = [[self.firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.firstAsset.duration)
                            ofTrack:firstOfTrack
                             atTime:kCMTimeZero
                              error:nil];
        
        /**
        // 这里是把两个视频叠加的效果
        AVMutableCompositionTrack *secondTrack = [self.mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *secondOfTrack = [[self.secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.secondAsset.duration)
                             ofTrack:secondOfTrack
                              atTime:kCMTimeZero
                               error:nil];
         */
 
        // 这里是视频推进的效果。注意和上面叠加效果的不同
        AVMutableCompositionTrack *secondTrack = [self.mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *secondOfTrack = [[self.secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, self.secondAsset.duration)
                             ofTrack:secondOfTrack
                              atTime:self.firstAsset.duration
                               error:nil];
        
        AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        /**
        // 判断时长，其实这段没用，时长直接用自己拍的视频时长就行了。
        CMTime finalDuration ;
        CMTime result;
        NSLog(@"values =%f and %f",CMTimeGetSeconds(self.firstAsset.duration),CMTimeGetSeconds(self.secondAsset.duration));
        if (CMTimeGetSeconds(self.firstAsset.duration) == CMTimeGetSeconds(self.secondAsset.duration)) {
            finalDuration = self.firstAsset.duration;
        } else if (CMTimeGetSeconds(self.firstAsset.duration) > CMTimeGetSeconds(self.secondAsset.duration)) {
            finalDuration = self.firstAsset.duration;
            result = CMTimeSubtract(self.firstAsset.duration, self.secondAsset.duration);
        } else {
            finalDuration = self.secondAsset.duration;
            result = CMTimeSubtract(self.secondAsset.duration, self.firstAsset.duration);
        }
         */
        
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,CMTimeAdd(self.firstAsset.duration, self.secondAsset.duration));
        
        // 第一个视频的架构层
        AVMutableVideoCompositionLayerInstruction *firstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
        [firstlayerInstruction setTransformRampFromStartTransform:CGAffineTransformIdentity
                                                   toEndTransform:CGAffineTransformMakeTranslation(-[UIScreen mainScreen].bounds.size.width, 0)
                                                        timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(6.0, 30),
                                                                                  CMTimeMakeWithSeconds(7.0, 30))];
        [firstlayerInstruction setOpacity:0.0 atTime:CMTimeMakeWithSeconds(12, 30)];
        
        // 第二个视频的架构层
        AVMutableVideoCompositionLayerInstruction *secondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
        //        [secondlayerInstruction setOpacityRampFromStartOpacity:0.7 toEndOpacity:0.2 timeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration)];
        [secondlayerInstruction setTransform:CGAffineTransformIdentity atTime:kCMTimeZero];
        [secondlayerInstruction setTransformRampFromStartTransform:CGAffineTransformMakeTranslation([UIScreen mainScreen].bounds.size.width, 0)
                                                    toEndTransform:CGAffineTransformIdentity
                                                         timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(7.0, 30),
                                                                                   CMTimeMakeWithSeconds(8.0, 30))];
        //        [secondlayerInstruction setTransformRampFromStartTransform:secondTrack.preferredTransform toEndTransform:CGAffineTransformMakeTranslation(320, 0) timeRange:CMTimeRangeMake(firstAsset.duration, CMTimeMake(firstAsset.duration.value+30, firstAsset.duration.timescale))];
        
        // 这个地方你把数组顺序倒一下，视频上下位置也跟着变了。
        mainInstruction.layerInstructions = [NSArray arrayWithObjects:firstlayerInstruction,secondlayerInstruction, nil];
        self.mainComposition = [AVMutableVideoComposition videoComposition];
        self.mainComposition.instructions = [NSArray arrayWithObjects:mainInstruction,nil];
        self.mainComposition.frameDuration = CMTimeMake(1, 30);
        self.mainComposition.renderSize = CGSizeMake(640, 480);
        
        // 导出路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"mergeVideo.mov"]];
                NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:myPathDocs error:NULL];
        NSURL *url = [NSURL fileURLWithPath:myPathDocs];
        NSLog(@"URL:-  %@", [url description]);
        
        // 导出
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:self.mixComposition presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL = url;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        exporter.videoComposition = self.mainComposition;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self exportDidFinish:exporter];
            });
        }];
    } else {
        [SVProgressHUD showErrorWithStatus:@"选择视频" maskType:SVProgressHUDMaskTypeBlack];
    }
}

#pragma mark - Private Method

/**
 *  输出完成
 */
- (void)exportDidFinish:(AVAssetExportSession *)session
{
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL])  {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        [SVProgressHUD showErrorWithStatus:@"存档失败" maskType:SVProgressHUDMaskTypeBlack];
                        [SVProgressHUD dismiss];
                    } else {
                        [SVProgressHUD showSuccessWithStatus:@"存档成功" maskType:SVProgressHUDMaskTypeBlack];
                        [SVProgressHUD dismiss];
                    }
                });
            }];
        }
    } else {
        [SVProgressHUD showErrorWithStatus:@"存档失败" maskType:SVProgressHUDMaskTypeBlack];
        [SVProgressHUD dismiss];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        self.picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    } else {
        self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    [self presentViewController:self.picker animated:YES completion:nil];
}

@end
