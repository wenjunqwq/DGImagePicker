//
//  CameraOverlayView.m
//  Daniel García 
//
//  Created by Daniel García on 3/20/12.
//  Copyright (c) 2012 JSoto, Inc. All rights reserved.
//

#warning TO-DO: ajustar los elementos del overlay

#define createBlockSafeSelf() __block typeof(self) blockSafeSelf = self;

#import <QuartzCore/QuartzCore.h>
#import "CameraOverlayView.h"
#import "DGImagePicker.h"
#import "JSBlocksButton.h"
#import "JSBlocksActionSheet.h"
#import "JSProgressHUD.h"
#import "ImageLibraryAssetManager.h"

#define kGalleryBoxSwitchSideAnimationDuration 0.20

#define kGaleryBoxLeftMargin 10
#define kGaleryBoxBottomMargin 7
#define kGalleryBoxWidth 37

#define kGalleryBottomControlsHeight 53
#define kCameraSwitchAnimationDuration 0.20
#define kCameraPicSwitchPositionOffsetY 41
#define kCameraPicSwitchPositionOffsetX 82
#define kCameraVidSwitchPositionOffsetY 41
#define kCameraVidSwitchPositionOffsetX 43
#define kCameraSwitchBGPositionOffsetY 25
#define kCameraSwitchBGPositionOffsetX 70
#define kCameraUpperControlsAreaHeight 70

#define kCameraFocustIndicatorSize 73.0f
#define kCameraFocustIndicatorFlickeringInterval 0.1f
#define kCameraFocustIndicatorFlickeringTime 2.0f

#define kCameraCancelButtonWidth 69 
#define kCameraCancelButtonHeight 36
#define kCameraCancelButtonPositionX0 5
#define kCameraCancelButtonPositionY0 25
#define kCameraCancelButtonPositionX90 20
#define kCameraCancelButtonPositionY90 -5
#define kCameraCancelButtonPositionX180 15
#define kCameraCancelButtonPositionX270 70
#define kCameraCancelButtonPositionY270 -17

#define kSwitchBackCameraButtonWidth 69 
#define kSwitchBackCameraButtonHeight 36
#define kSwitchBackCameraButtonPositionX0 246
#define kSwitchBackCameraButtonPositionY0 26
#define kSwitchBackCameraButtonPositionX90 335
#define kSwitchBackCameraButtonPositionY90 237
#define kSwitchBackCameraButtonPositionX180 489
#define kSwitchBackCameraButtonPositionX270 388
#define kSwitchBackCameraButtonPositionY270 -256

#define kVideoCounterWidth 92
#define kVideoCounterHeight 29
#define kVideoCounterMarginX 8
#define kVideoCounterMarginY 27
#define kVideoCounterPositionX0 11
#define kVideoCounterPositionY0 25
#define kVideoCounterPositionX90 60
#define kVideoCounterPositionY90 -35
#define kVideoCounterPositionX180 0
#define kVideoCounterPositionX270 -35
#define kVideoCounterPositionY270 50

@interface CameraOverlayView(){
    
}
@property (retain,nonatomic) NSDate *videoRecordingTimeStart;
@property (retain,nonatomic) NSTimer *videoRecordingTimer;
@property (nonatomic)        BOOL picCameraMode;
@property (nonatomic)        BOOL picFrontCameraMode;
@property (nonatomic)        BOOL recordingVideo;
@property (nonatomic)        BOOL recordingButtonOn;
@property (retain,nonatomic) UIView         *videoCounterContainer;
@property (retain,nonatomic) UIImageView    *switchCameraPicIcon;
@property (retain,nonatomic) UIImageView    *switchCameraVidIcon;
@property (retain,nonatomic) UIImageView    *cameraSwitchBG;
@property (retain,nonatomic) UIImageView    *focusTapIndicator;
@property (retain,nonatomic) NSTimer        *focusIndicatorFlickeringTimer;
@property (nonatomic)        BOOL           focusIndicatorHighlighed;
@property (retain,nonatomic) NSDate         *focusIndicatroFlickeringStart;
@property (retain,nonatomic) JSBlocksButton *shotButton;
@property (retain,nonatomic) JSBlocksButton *shotButtonVideo;
@property (retain,nonatomic) JSBlocksButton *cameraSwitchButton;
@property (retain,nonatomic) JSBlocksButton *cancelButton;
@property (retain,nonatomic) JSBlocksButton *switchFrontCamera;
@property (nonatomic, retain) UIActivityIndicatorView *galleryLastPictureLoadingSpinner;
@property (nonatomic, retain) UIView *galleryButtonBox;
@property (nonatomic, retain) UIImageView *lastPictureImageView;

- (void) updateVideoCounter:(NSTimer*)theTimer;
- (CGRect)galleryImageBoxFrame;
- (CGAffineTransform)galleryImageBoxTransformForDeviceOrientation:(UIDeviceOrientation)orientation;
- (CGAffineTransform)cancelButtonTransformForDeviceOrientation:(UIDeviceOrientation)orientation;
- (CGAffineTransform)videoCounterTransformForDeviceOrientation:(UIDeviceOrientation)orientation;
- (void)addObservers;
- (void)removeObservers;
@end

@implementation CameraOverlayView
@synthesize focusIndicatroFlickeringStart=_focusIndicatroFlickeringStart;
@synthesize focusTapIndicator=_focusTapIndicator;
@synthesize focusIndicatorFlickeringTimer=_focusIndicatorFlickeringTimer;
@synthesize focusIndicatorHighlighed=_focusIndicatorHighlighed;
@synthesize switchFrontCamera =_switchFrontCamera;
@synthesize cameraPicker;
@synthesize delegate = _delegate;
@synthesize galleryLastPictureLoadingSpinner = _galleryLastPictureLoadingSpinner;
@synthesize galleryButtonBox = _galleryButtonBox;
@synthesize lastPictureImageView = _lastPictureImageView;
@synthesize photoAndVideo;
@synthesize shotButton,shotButtonVideo,cameraSwitchButton,cancelButton;
@synthesize videoCounterContainer;
@synthesize picCameraMode,picFrontCameraMode,recordingVideo,recordingButtonOn;
@synthesize switchCameraPicIcon,switchCameraVidIcon,cameraSwitchBG;
@synthesize videoRecordingTimer,videoRecordingTimeStart;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.picCameraMode =YES;
        self.picFrontCameraMode =NO;
        self.recordingVideo=NO;
        CGSize screenSize = [UIScreen mainScreen].bounds.size;

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.galleryButtonBox = [[UIView alloc] initWithFrame:[self galleryImageBoxFrame]];
        _galleryButtonBox.transform = [self galleryImageBoxTransformForDeviceOrientation:[UIDevice currentDevice].orientation];
        _galleryButtonBox.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        _galleryButtonBox.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
        
        self.lastPictureImageView = [[UIImageView alloc] initWithFrame:_galleryButtonBox.bounds];
        _lastPictureImageView.contentMode = UIViewContentModeScaleAspectFill;
        _lastPictureImageView.clipsToBounds = YES;
        
        self.galleryLastPictureLoadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _galleryLastPictureLoadingSpinner.hidesWhenStopped = YES;
        _galleryLastPictureLoadingSpinner.center = _lastPictureImageView.center;
        [_galleryButtonBox addSubview:_galleryLastPictureLoadingSpinner];
        [_galleryLastPictureLoadingSpinner release];
        
        [_galleryButtonBox addSubview:_lastPictureImageView];
        [_lastPictureImageView release];
        
        createBlockSafeSelf();        
        JSBlocksButton *galleryImageButton = [JSBlocksButton buttonWithType:UIButtonTypeCustom tapCallback:^(JSBlocksButton *button) {
            [blockSafeSelf.delegate cameraOverlayViewGalleryButtonPressed:blockSafeSelf];
        }];
        galleryImageButton.frame = [self galleryImageBoxFrame];
        UIView *bottomControlsView=[[UIView alloc]initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - kGalleryBottomControlsHeight, [[UIScreen mainScreen] bounds].size.width, kGalleryBottomControlsHeight)];
        UIImageView *bottomBG=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"cameraBottomControlsBG.png"]];
        bottomBG.frame=CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, kGalleryBottomControlsHeight);
        
        // Shot Button
            self.shotButton = [JSBlocksButton buttonWithType:UIButtonTypeCustom tapCallback:^(JSBlocksButton *button) {
                [self shotPhotoCamera];
            }];
            self.shotButton.imageView.contentMode=UIViewContentModeCenter;
            [self.shotButton setBackgroundImage:[UIImage imageNamed:@"cameraShotButton.png"] forState:UIControlStateNormal];        
            [self.shotButton setImage:[UIImage imageNamed:@"cameraShotButtonPicIcon.png"] forState:UIControlStateNormal];
            CGRect btnframe=CGRectMake(0, 0, 98, 40);
            btnframe.origin.x=(bottomControlsView.frame.size.width/2)-(btnframe.size.width/2);
            btnframe.origin.y=(bottomControlsView.frame.size.height/2)-(btnframe.size.height/2);
            self.shotButton.frame=btnframe;        
        //- Shot Button
        
        // Shot Button Video
            self.shotButtonVideo = [JSBlocksButton buttonWithType:UIButtonTypeCustom tapCallback:^(JSBlocksButton *button) {                
                [self shotVideoCamera];
            }];
            self.shotButtonVideo.imageView.contentMode=UIViewContentModeCenter;
            [self.shotButtonVideo setBackgroundImage:[UIImage imageNamed:@"cameraShotButton.png"] forState:UIControlStateNormal];        
            [self.shotButtonVideo setImage:[UIImage imageNamed:@"recordingOff.png"] forState:UIControlStateNormal];
            CGRect btnVideoFrame=CGRectMake(0, 0, 98, 40);
            btnVideoFrame.origin.x=(bottomControlsView.frame.size.width/2)-(btnVideoFrame.size.width/2);
            btnVideoFrame.origin.y=(bottomControlsView.frame.size.height/2)-(btnVideoFrame.size.height/2);
            self.shotButtonVideo.frame=btnVideoFrame; 
            self.shotButtonVideo.hidden=YES;
        //- Shot Button Video
        
        // Video Counter
            self.videoCounterContainer=[[UIView alloc]initWithFrame:CGRectMake(screenSize.width-kVideoCounterWidth-kVideoCounterMarginX, 0+kVideoCounterMarginY,kVideoCounterWidth,kVideoCounterHeight)];
            self.videoCounterContainer.backgroundColor=[[UIColor blackColor]colorWithAlphaComponent:0.4];
            NSString *counterText=@"00:00:00";
            UIFont *counterFont=[UIFont fontWithName:@"Helvetica" size:19.0];
            CGSize counterTextSize=[counterText sizeWithFont:counterFont];
            UILabel *counterTextLabel=[[[UILabel alloc]initWithFrame:CGRectMake((kVideoCounterWidth-counterTextSize.width)/2, (kVideoCounterHeight-counterTextSize.height)/2, counterTextSize.width, counterTextSize.height)]autorelease];
            counterTextLabel.font=counterFont;
            counterTextLabel.textColor=[UIColor whiteColor];            
            counterTextLabel.backgroundColor=[UIColor clearColor];
            counterTextLabel.text=counterText;        
            [self.videoCounterContainer addSubview:counterTextLabel];        
            self.videoCounterContainer.layer.cornerRadius=5;
            self.videoCounterContainer.layer.borderWidth=1.0;
            self.videoCounterContainer.layer.borderColor=[[UIColor whiteColor]colorWithAlphaComponent:0.4].CGColor;
            self.videoCounterContainer.hidden=YES;
        //- Video Counter
                
        // Camera Switch Button            
            self.cameraSwitchButton = [JSBlocksButton buttonWithType:UIButtonTypeCustom tapCallback:^(JSBlocksButton *button) {
                if(self.picCameraMode){
                    cameraPicker.cameraCaptureMode=UIImagePickerControllerCameraCaptureModeVideo;
                    [UIView animateWithDuration:kCameraSwitchAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        CGRect switchBtnFrame=CGRectMake(0, 0, 50, 50);
                        switchBtnFrame.origin.x=bottomControlsView.frame.size.width-kCameraVidSwitchPositionOffsetX;
                        switchBtnFrame.origin.y=bottomControlsView.frame.size.height-kCameraVidSwitchPositionOffsetY;
                        self.cameraSwitchButton.frame=switchBtnFrame;
                    } completion:^(BOOL finished) {
                    }];                    
                }else{
                    cameraPicker.cameraCaptureMode=UIImagePickerControllerCameraCaptureModePhoto;
                    [UIView animateWithDuration:kCameraSwitchAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        CGRect switchBtnFrame=CGRectMake(0, 0, 50, 50);
                        switchBtnFrame.origin.x=bottomControlsView.frame.size.width-kCameraPicSwitchPositionOffsetX;
                        switchBtnFrame.origin.y=bottomControlsView.frame.size.height-kCameraPicSwitchPositionOffsetY;
                        self.cameraSwitchButton.frame=switchBtnFrame;
                    } completion:^(BOOL finished) {
                    }];                    
                }
                self.picCameraMode=!self.picCameraMode;
                self.shotButton.hidden=!self.picCameraMode;
                self.shotButtonVideo.hidden=self.picCameraMode;
            }];
            [self.cameraSwitchButton setImage:[UIImage imageNamed:@"cameraSwitch.png"] forState:UIControlStateNormal];   
            self.cameraSwitchButton.imageView.contentMode=UIViewContentModeCenter;
        //self.cameraSwitchButton.backgroundColor=[UIColor redColor];
            self.cameraSwitchBG = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"cameraBottomSwitcherBG.png"]];
            self.cameraSwitchBG.frame = CGRectMake(bottomControlsView.frame.size.width-kCameraSwitchBGPositionOffsetX, bottomControlsView.frame.size.height-kCameraSwitchBGPositionOffsetY, self.cameraSwitchBG.image.size.width, self.cameraSwitchBG.image.size.height);
            CGRect switchBtnFrame=CGRectMake(0, 0, 50, 50);
            switchBtnFrame.origin.x=bottomControlsView.frame.size.width-kCameraPicSwitchPositionOffsetX;
            switchBtnFrame.origin.y=bottomControlsView.frame.size.height-kCameraPicSwitchPositionOffsetY;
            self.cameraSwitchButton.frame=switchBtnFrame;        
            self.switchCameraPicIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"picCameraIcon.png"]];
            CGRect switchPicIconFrame=CGRectMake(0, 0, 16, 14);
            switchPicIconFrame.origin.x=bottomControlsView.frame.size.width-67;
            switchPicIconFrame.origin.y=bottomControlsView.frame.size.height-44;
            self.switchCameraPicIcon.frame=switchPicIconFrame;        
            self.switchCameraVidIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"vidCameraIcon.png"]];
            CGRect switchVidIconFrame=CGRectMake(0, 0, 18, 12);
            switchVidIconFrame.origin.x=bottomControlsView.frame.size.width-27;
            switchVidIconFrame.origin.y=bottomControlsView.frame.size.height-43;
            self.switchCameraVidIcon.frame=switchVidIconFrame;        
        //- Camera Switch Button
        
        // Cancel/Exit Button
            self.cancelButton = [JSBlocksButton buttonWithType:UIButtonTypeCustom tapCallback:^(JSBlocksButton *button) {
                if ([self.delegate respondsToSelector:@selector(cameraCancel)])
                {
                    [self.delegate cameraCancel];
                }
            }];
            [self.cancelButton setTitle:NSLocalizedString(@"DGImagePickerCameraBackButtonLabel", nil) forState:UIControlStateNormal];
            [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            self.cancelButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:13];        
            [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"cameraBackButton.png"] forState:UIControlStateNormal];

            CGRect cancelBtnframe=CGRectMake(kCameraCancelButtonPositionX0, kCameraCancelButtonPositionY0, kCameraCancelButtonWidth, kCameraCancelButtonHeight);
            self.cancelButton.frame=cancelBtnframe;
        //- Cancel/Exit Button
        
        // Switch Front/Back Button
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerCameraDeviceRear]){
            self.switchFrontCamera = [JSBlocksButton buttonWithType:UIButtonTypeCustom tapCallback:^(JSBlocksButton *button) {
                if (!self.picFrontCameraMode){
                    self.cameraPicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                }else{
                    self.cameraPicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
                }
                self.picFrontCameraMode=!self.picFrontCameraMode;
            }];
            [self.switchFrontCamera setBackgroundImage:[UIImage imageNamed:@"PLCameraToggle.png"] forState:UIControlStateNormal];
            [self.switchFrontCamera setBackgroundImage:[UIImage imageNamed:@"PLCameraTogglePressed.png"] forState:UIControlStateSelected];
            CGRect switchCameraBtnframe=CGRectMake(kSwitchBackCameraButtonPositionX0, kSwitchBackCameraButtonPositionY0, kSwitchBackCameraButtonWidth, kSwitchBackCameraButtonHeight);
            self.switchFrontCamera.frame=switchCameraBtnframe;
        }
        //- Switch Front/Back Button
        
        // Focus Tap Gesture Recognizer and Tap Indicator View
            UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:nil];
            [self addGestureRecognizer:gestureRecognizer];
            gestureRecognizer.delegate=self;
            [gestureRecognizer release];
            self.focusTapIndicator=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, kCameraFocustIndicatorSize, kCameraFocustIndicatorSize)];
            self.focusTapIndicator.image=[UIImage imageNamed:@"PLFocusCrosshairsSmall0.png"];
            self.focusTapIndicator.hidden=YES;
        //- Focus Tap Gesture Recognizer and Tap Indicator View
        
        [bottomControlsView addSubview:_galleryButtonBox];
        [bottomControlsView addSubview:bottomBG];
        [bottomControlsView addSubview:self.shotButton];
        [bottomControlsView addSubview:self.shotButtonVideo];
        [bottomControlsView addSubview:galleryImageButton];  
        [bottomControlsView addSubview:self.cameraSwitchBG];
        [bottomControlsView addSubview:self.cameraSwitchButton];
        [bottomControlsView addSubview:self.switchCameraPicIcon];
        [bottomControlsView addSubview:self.switchCameraVidIcon];
        
        [self addSubview:self.focusTapIndicator];
        [self addSubview:bottomControlsView];
        [self addSubview:self.cancelButton];
        [self addSubview:self.switchFrontCamera];
        [self addSubview:self.videoCounterContainer];
        [bottomControlsView release];     
    }
    
    return self;
}
-(IBAction) handleTapGesture:(UIGestureRecognizer *) sender withTouch:(UITouch *)touch {
    CGPoint touchPoint=[touch locationInView:self];
    if(touchPoint.y>kCameraUpperControlsAreaHeight && touchPoint.y<(self.frame.size.height-kGalleryBottomControlsHeight)){
        CGRect focusTapFrame=self.focusTapIndicator.frame;
        focusTapFrame.origin.x=touchPoint.x-(focusTapFrame.size.width/2);
        focusTapFrame.origin.y=touchPoint.y-(focusTapFrame.size.height/2);
        self.focusTapIndicator.frame=focusTapFrame;
        self.focusTapIndicator.hidden=NO;
        if([self.focusIndicatorFlickeringTimer isValid])
            [self.focusIndicatorFlickeringTimer invalidate];
        self.focusIndicatroFlickeringStart=[NSDate date];
        self.focusIndicatorFlickeringTimer=[NSTimer scheduledTimerWithTimeInterval:kCameraFocustIndicatorFlickeringInterval target:self selector:@selector(focusFlickeringTimeCounter:) userInfo:nil repeats:YES];                    
        [self.focusIndicatorFlickeringTimer fire];
    }
}
- (void) focusFlickeringTimeCounter:(NSTimer*)theTimer{
    double elapsedTime = -[self.focusIndicatroFlickeringStart timeIntervalSinceNow];
    if(!self.focusIndicatorHighlighed){
        self.focusTapIndicator.image=[UIImage imageNamed:@"PLFocusCrosshairsSmall0.png"];
    }else{
        self.focusTapIndicator.image=[UIImage imageNamed:@"PLFocusCrosshairsSmall1.png"];
    }
    self.focusIndicatorHighlighed=!self.focusIndicatorHighlighed;
    if(elapsedTime>=kCameraFocustIndicatorFlickeringTime){
        self.focusTapIndicator.hidden=YES;
        [theTimer invalidate];
    }
    
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    [self handleTapGesture:gestureRecognizer withTouch:touch];
    return NO;
}
- (void)shotPhotoCamera{
    CATransition *animation = [CATransition animation];
    animation.delegate = self;
    animation.duration = 0.5;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = @"cameraIris";
    [self.window.layer addAnimation:animation forKey:nil];
    [cameraPicker takePicture];
}
- (void)shotVideoCamera{
    if(self.recordingVideo){                    
        self.cancelButton.hidden=NO;
        self.switchFrontCamera.hidden=NO;
        [self.shotButtonVideo setImage:[UIImage imageNamed:@"recordingOff.png"] forState:UIControlStateNormal];
        self.videoCounterContainer.hidden=YES;
        ((DGImagePicker *)self.delegate).progressHud=[JSProgressHUD progressViewInView:self];
        [((DGImagePicker *)self.delegate).progressHud showWithStatus:@"Guardando Vídeo" maskType:JSProgressHUDMaskTypeBlack];
        [cameraPicker stopVideoCapture];
        [self.videoRecordingTimer invalidate];                    
    }else{
        self.cancelButton.hidden=YES;
        self.switchFrontCamera.hidden=YES;
        [self.shotButtonVideo setImage:[UIImage imageNamed:@"recordingOn.png"] forState:UIControlStateNormal];
        self.videoCounterContainer.hidden=NO;
        [cameraPicker startVideoCapture];
        self.videoRecordingTimeStart=[NSDate date];
        self.videoRecordingTimer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateVideoCounter:) userInfo:nil repeats:YES];                    
        [self.videoRecordingTimer fire];
    }
    self.recordingVideo=!self.recordingVideo;
}
- (void)setPhotoAndVideo:(BOOL)_photoAndVideo{
    photoAndVideo=_photoAndVideo;
    self.cameraSwitchButton.hidden=!photoAndVideo;
    self.switchCameraPicIcon.hidden=!photoAndVideo;
    self.switchCameraVidIcon.hidden=!photoAndVideo;
    self.cameraSwitchBG.hidden=!photoAndVideo;
}
- (void)resetOriginalState{
    UIView *bottomControlsView=[[UIView alloc]initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - kGalleryBottomControlsHeight, [[UIScreen mainScreen] bounds].size.width, kGalleryBottomControlsHeight)];
    self.cameraPicker.cameraCaptureMode=UIImagePickerControllerCameraCaptureModePhoto;    
    CGRect switchBtnFrame=CGRectMake(0, 0, 50, 50);
    switchBtnFrame.origin.x=bottomControlsView.frame.size.width-kCameraPicSwitchPositionOffsetX;
    switchBtnFrame.origin.y=bottomControlsView.frame.size.height-kCameraPicSwitchPositionOffsetY;
    self.cameraSwitchButton.frame=switchBtnFrame;
    self.picCameraMode=YES;
    self.picFrontCameraMode=NO;
    self.shotButton.hidden=!self.picCameraMode;
    self.shotButtonVideo.hidden=self.picCameraMode;
}
- (void) updateVideoCounter:(NSTimer*)theTimer{
    NSUInteger elapsedTime = -[self.videoRecordingTimeStart timeIntervalSinceNow];
    if(!self.recordingButtonOn){
        [self.shotButtonVideo setImage:[UIImage imageNamed:@"recordingOn.png"] forState:UIControlStateNormal];
    }else{
        [self.shotButtonVideo setImage:[UIImage imageNamed:@"recordingOff.png"] forState:UIControlStateNormal];
    }
    self.recordingButtonOn=!self.recordingButtonOn;
    NSInteger elapsedHours=(int)((elapsedTime/60)/60);
    NSInteger elapsedMinutes=(int)((elapsedTime/60)-(elapsedHours*60));
    NSInteger elapsedSecons=(int)(elapsedTime-(elapsedHours*60*60)-(elapsedMinutes*60));
    NSArray *counterSubviews=[self.videoCounterContainer subviews];
    ((UILabel*)[counterSubviews objectAtIndex:0]).text=[NSString stringWithFormat:@"%02d:%02d:%02d",elapsedHours,elapsedMinutes,elapsedSecons];
}
-(void)controlsHidden:(BOOL)hidden{

}
- (CGRect)galleryImageBoxFrame
{    
    CGRect frame = CGRectMake(kGaleryBoxLeftMargin, kGalleryBottomControlsHeight - kGaleryBoxBottomMargin - kGalleryBoxWidth, kGalleryBoxWidth, kGalleryBoxWidth);
    return frame;
}

- (CGAffineTransform)galleryImageBoxTransformForDeviceOrientation:(UIDeviceOrientation)orientation
{
    //CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2); // 90 degrees
            //transform = CGAffineTransformTranslate(transform, -(screenSize.height - kGaleryBoxBottomMargin - kGalleryBoxWidth - kGaleryBoxLeftMargin), 0);
            break;
        case UIDeviceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2); // -90 degrees
            //transform = CGAffineTransformTranslate(transform, 0, screenSize.width - kGaleryBoxLeftMargin * 2 - kGalleryBoxWidth);
            break;
        case UIDeviceOrientationPortrait:
            // Identity transform
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI); // 180 degrees
            //transform = CGAffineTransformTranslate(transform, -(screenSize.width - kGaleryBoxLeftMargin * 2 - kGalleryBoxWidth), 0);
            break;
        default: break;
    }
    
    return transform;
}

- (CGAffineTransform)cancelButtonTransformForDeviceOrientation:(UIDeviceOrientation)orientation
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2); // 90 degrees
            transform = CGAffineTransformTranslate(transform, kCameraCancelButtonPositionX90 , 0 -(screenSize.width - kCameraCancelButtonPositionY90 - kCameraCancelButtonWidth));
            break;
        case UIDeviceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2); // -90 degrees
            transform = CGAffineTransformTranslate(transform,  0 - screenSize.height +kCameraCancelButtonWidth + kCameraCancelButtonPositionX270 , 0 +  kCameraCancelButtonPositionY270);
            break;
        case UIDeviceOrientationPortrait:
            // Identity transform
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI); // 180 degrees
            transform = CGAffineTransformTranslate(transform, 0 - screenSize.width + kCameraCancelButtonPositionX180 + kCameraCancelButtonWidth, 0);
            break;
        default: break;
    }
    
    return transform;
}
- (CGAffineTransform)switchCameraFrontButtonTransformForDeviceOrientation:(UIDeviceOrientation)orientation
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2); // 90 degrees
            transform = CGAffineTransformTranslate(transform, kSwitchBackCameraButtonPositionX90 , 0 -(screenSize.width - kSwitchBackCameraButtonPositionY90 - kSwitchBackCameraButtonWidth));
            break;
        case UIDeviceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2); // -90 degrees
            transform = CGAffineTransformTranslate(transform,  0 - screenSize.height +kSwitchBackCameraButtonWidth + kSwitchBackCameraButtonPositionX270 , 0 +  kSwitchBackCameraButtonPositionY270);
            break;
        case UIDeviceOrientationPortrait:
            // Identity transform
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI); // 180 degrees
            transform = CGAffineTransformTranslate(transform, 0 - screenSize.width + kSwitchBackCameraButtonPositionX180 + kSwitchBackCameraButtonWidth, 0);
            break;
        default: break;
    }
    
    return transform;
}
- (CGAffineTransform)videoCounterTransformForDeviceOrientation:(UIDeviceOrientation)orientation
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    
    switch (orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2); // 90 degrees
            transform = CGAffineTransformTranslate(transform, 0 + screenSize.height - kVideoCounterWidth - kVideoCounterPositionX90 , 0 + kVideoCounterPositionY90);
            //transform = CGAffineTransformTranslate(transform, kVideoCounterPositionX90 , 0 -(screenSize.width - kVideoCounterPositionY90 - kVideoCounterWidth));
            break;
        case UIDeviceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2); // -90 degrees
            transform = CGAffineTransformTranslate(transform,  0 + kVideoCounterPositionX270, 0 - screenSize.width + kVideoCounterHeight +  kVideoCounterPositionY270);
            break;
        case UIDeviceOrientationPortrait:
            // Identity transform
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI); // 180 degrees
            transform = CGAffineTransformTranslate(transform, 0 - screenSize.width + kVideoCounterPositionX180 + kVideoCounterWidth, 0);
            break;
        default: break;
    }
    
    return transform;
}


- (void)screenDidRotate:(NSNotification *)note
{    
    static UIDeviceOrientation lastDeviceOrientation = -2;
    UIDeviceOrientation newDeviceOrientation = [UIDevice currentDevice].orientation;
    
    BOOL deviceOrientationChangedSinceLastTime = newDeviceOrientation != lastDeviceOrientation;
    
    if (UIDeviceOrientationIsValidInterfaceOrientation(newDeviceOrientation) && deviceOrientationChangedSinceLastTime && !self.recordingVideo)
    {        
        BOOL animated = [[note.userInfo valueForKey:@"UIDeviceOrientationRotateAnimatedUserInfoKey"] boolValue];
        
        NSTimeInterval animationDuration = animated ? kGalleryBoxSwitchSideAnimationDuration : 0.0;   
        
        [UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.galleryButtonBox.transform = [self galleryImageBoxTransformForDeviceOrientation:newDeviceOrientation];
            self.switchCameraPicIcon.transform = [self galleryImageBoxTransformForDeviceOrientation:newDeviceOrientation];
            self.switchCameraVidIcon.transform = [self galleryImageBoxTransformForDeviceOrientation:newDeviceOrientation];
            self.shotButton.imageView.transform = [self galleryImageBoxTransformForDeviceOrientation:newDeviceOrientation];
            self.cancelButton.alpha=0.0f;            
            self.switchFrontCamera.alpha=0.0f;
            self.videoCounterContainer.alpha=0.0f;
            self.videoCounterContainer.transform = [self videoCounterTransformForDeviceOrientation:newDeviceOrientation];
        } completion:^(BOOL finished) {
            self.cancelButton.transform = [self cancelButtonTransformForDeviceOrientation:newDeviceOrientation];                            
            self.switchFrontCamera.transform = [self switchCameraFrontButtonTransformForDeviceOrientation:newDeviceOrientation];                           
            [UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.cancelButton.alpha=1.0f;
                self.videoCounterContainer.alpha=1.0f;
                self.switchFrontCamera.alpha=1.0f;
            } completion:^(BOOL finished) {
                
            }];
        }];
    }
    
    lastDeviceOrientation = newDeviceOrientation;
}
- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    BOOL viewDisappeared = (newWindow == nil);
    
    if (viewDisappeared)
    {
        [self removeObservers];
        
        if ([self.delegate respondsToSelector:@selector(cameraOverlayViewDidDisappearFromScreen:)])
        {
            [self.delegate cameraOverlayViewDidDisappearFromScreen:self];
        }
    }
    else
    {
        [self addObservers];
        
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        if (UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation))
            self.galleryButtonBox.transform = [self galleryImageBoxTransformForDeviceOrientation:deviceOrientation];
    }
}

#pragma mark - Public

- (void)updateLastPhotoTaken
{
    [self.galleryLastPictureLoadingSpinner startAnimating];
    
    createBlockSafeSelf();
    __block typeof (_delegate) blockSafeDelegate = _delegate;
    [ImageLibraryAssetManager loadLastPhotoTakenWithCallback:^(UIImage *thumbnail, UIImage *_fullResolutionImage) {
        blockSafeSelf.lastPictureImageView.image = thumbnail;
        [blockSafeSelf.galleryLastPictureLoadingSpinner stopAnimating];
        
        [blockSafeDelegate cameraOverlayView:blockSafeSelf lastPictureFromGalleryLoaded:_fullResolutionImage];
    }];
}

#pragma mark - Memory Management
            
- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PLCameraDeviceOrientationChangedNotification" object:nil];
}

- (void)dealloc
{
    [_focusIndicatorFlickeringTimer invalidate];
    [_focusIndicatorFlickeringTimer release];
    [_focusIndicatroFlickeringStart release];
    [_switchFrontCamera release];
    [_focusTapIndicator release];
    [videoRecordingTimer release];
    [videoCounterContainer release];
    [shotButton release];
    [shotButtonVideo release];
    [switchCameraPicIcon release];
    [switchCameraVidIcon release];
    [cameraSwitchBG release];
    [cameraSwitchButton release];
    [_galleryLastPictureLoadingSpinner release];
    [_galleryButtonBox release];
    [_lastPictureImageView release];
    
    [self removeObservers];
    
    [super dealloc];
}


@end
