//
//  Draw2ViewController.h
//  Draw2
//
//  Created by Billy Liang on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Draw2InputViewController.h"
#import "CameraPreviewController.h"
#import "Draw2SaveController.h"
#import "ImportViewController.h"

@class Draw2View;

/* the order of this enum must be 
   kept in sync with the android 
   and flex code
 */
typedef enum error_code_ {
    ERROR_SESSION_EXISTED,
} error_code_t;

typedef enum draw_mode_ {
    NONE_ACTIVE,
    DRAW,
    ERASE,
} draw_mode_t;

typedef enum ui_color_ {
    BLACK,
    RED,
    GREEN,
    BLUE,
} ui_color_t;

typedef enum network_op_ {
    NONE,
    START_SESSION,
    JOIN_SESSION
} network_op_t;

typedef enum network_role_ {
    GENERAL,
    HOST,
    CLIENT
} network_role_t;

typedef struct color_marker_ {
    ui_color_t color;
    NSInteger boundary;
} color_marker_t;

@interface Draw2ViewController : UIViewController <NSStreamDelegate, Draw2InputViewDelegate,
                                                   UIImagePickerControllerDelegate, UINavigationControllerDelegate, 
                                                   CameraPreviewViewDelegate, Draw2SaveControllerDelegate, ImportControllerDelegate> {
    
    draw_mode_t mode;
    ui_color_t color;
    network_op_t netOp;
}

@property (nonatomic, strong) NSMutableArray *points;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, copy) NSString *sessionID;
@property (nonatomic, strong) NSDate *dateTime;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSOutputStream *imageOutStream;
@property (nonatomic, strong) NSInputStream *imageInStream;
@property (nonatomic, strong) NSOperationQueue *toServerQ;
@property (nonatomic, strong) NSOperationQueue *fromServerQ;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *serverIP;
@property (nonatomic, strong) UIImage *imageToUpload;
@property (nonatomic, strong) NSMutableData *rawData;
@property (nonatomic, copy) NSString *clientHost;
@property (nonatomic, strong) NSMutableArray *markerArray;
@property (nonatomic, strong) UIPopoverController *popOver;
@property (nonatomic, strong) NSMutableDictionary *lastPointFromUser;
@property (nonatomic, strong) IBOutlet UIButton *connectionButton;
@property (nonatomic) NSInteger clientPort;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic) NSInteger readIndex;
@property (nonatomic) NSInteger pageIndex;
@property (nonatomic) NSInteger fileSize;
@property (nonatomic) NSInteger rawBytesRead;
@property (nonatomic, strong) UIButton *pensil;
@property (nonatomic) Boolean connected;


- (IBAction) sendPoints:(id)sender;
- (IBAction) startSession:(id)sender;
- (IBAction) getPoints:(id)sender;
- (void) setMode:(draw_mode_t)drawingMode;
- (draw_mode_t) getMode;
- (IBAction) setEdittingMode:(id)sender;
- (IBAction) setColor:(id)sender;
- (ui_color_t) getColor;
- (IBAction) deleteDrawing:(id)sender;
- (IBAction) joinSession:(id)sender;
- (void)sendCoordinates:(NSTimer*)theTimer;
- (void) updateImageView:(NSData *)imageData;
//- (void)sendCoordinates;
- (NSString *) getColorScheme:(ui_color_t)colorValue;
-(IBAction) takePicture:(id)sender;
-(IBAction) saveDrawing:(id)sender;
- (Boolean) isConnected;

@end
