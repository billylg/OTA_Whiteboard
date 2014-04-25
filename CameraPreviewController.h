//
//  CameraPreviewController.h
//  Draw2
//
//  Created by Billy Liang on 10/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
//#import "AVCaptureOutput.h"

@protocol CameraPreviewViewDelegate <NSObject>

- (void) cameraCaptureDidFinished:(UIImage *)capturedImage;
           
@end


@interface CameraPreviewController : UIViewController {
    IBOutlet UIView *vImagePreview;
    AVCaptureStillImageOutput *stillImageOutput;
    id <CameraPreviewViewDelegate> delegate;
}

@property(nonatomic, retain) IBOutlet UIView *vImagePreview;
@property(nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (assign) id <CameraPreviewViewDelegate> delegate;

-(IBAction) captureNow;

@end
