//
//  CameraPreviewController.m
//  Draw2
//
//  Created by Billy Liang on 10/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CameraPreviewController.h"
//#import "AVCaptureSession.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>

@implementation CameraPreviewController

@synthesize vImagePreview;
@synthesize stillImageOutput;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [stillImageOutput release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
- (void) viewWillAppear:(BOOL)animated
{
    CGAffineTransform xform = CGAffineTransformMakeRotation(3*M_PI/2);
    self.view.transform = xform;
    CGRect contentRect = CGRectMake(0,0, 1024, 768);
	self.view.bounds = contentRect;
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
	session.sessionPreset = AVCaptureSessionPresetMedium;
    
	CALayer *viewLayer = self.vImagePreview.layer;
    NSLog(@"viewLayer = %@", viewLayer);
    
	AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    
    CGRect bounds=viewLayer.bounds;
    NSLog(@"camera view bounds width = %f, height = %f", bounds.size.width, bounds.size.height);
    bounds.size.height = bounds.size.height - 50;
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    captureVideoPreviewLayer.bounds = bounds;
    captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
	//captureVideoPreviewLayer.frame = self.vImagePreview.bounds;
    [self.vImagePreview.layer addSublayer:captureVideoPreviewLayer];
    
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
	NSError *error = nil;
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	if (!input) {
		// Handle the error appropriately.
		NSLog(@"ERROR: trying to open camera: %@", error);
	}
	[session addInput:input];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:stillImageOutput];
	[session startRunning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}
 */

-(IBAction) captureNow
{
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in stillImageOutput.connections)
	{
		for (AVCaptureInputPort *port in [connection inputPorts])
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo] )
			{
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) { break; }
	}
    
	NSLog(@"about to request a capture from: %@", stillImageOutput);
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
		 CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
		 if (exifAttachments)
		 {
             // Do something with the attachments.
             NSLog(@"attachements: %@", exifAttachments);
		 }
         else
             NSLog(@"no attachments");
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         NSLog(@"image orientation is %d", [image imageOrientation]);
         
         // calculate the size of the rotated view's containing box for our drawing space
         UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
         CGAffineTransform t = CGAffineTransformMakeRotation(2*M_PI);
         rotatedViewBox.transform = t;
         CGSize rotatedSize = rotatedViewBox.frame.size;
         [rotatedViewBox release];
         
         // Create the bitmap context
         UIGraphicsBeginImageContext(rotatedSize);
         CGContextRef bitmap = UIGraphicsGetCurrentContext();
         
         // Move the origin to the middle of the image so we will rotate and scale around the center.
         CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
         
         //   // Rotate the image context
         CGContextRotateCTM(bitmap, 2*M_PI);
         
         // Now, draw the rotated/scaled image into the context
         CGContextScaleCTM(bitmap, 1.0, -1.0);
         CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
         
         UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
         UIGraphicsEndImageContext();
         
         [self.delegate cameraCaptureDidFinished:newImage];
         [self.parentViewController dismissModalViewControllerAnimated:YES];
         
	 }];
}

@end
