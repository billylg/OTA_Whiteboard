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
}

@property(nonatomic, strong) IBOutlet UIView *vImagePreview;
@property(nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (copy) id <CameraPreviewViewDelegate> delegate;

-(IBAction) captureNow;

@end
