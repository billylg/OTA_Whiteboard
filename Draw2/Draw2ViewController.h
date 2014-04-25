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
    int boundary;
} color_marker_t;

@interface Draw2ViewController : UIViewController <NSStreamDelegate, Draw2InputViewDelegate,
                                                   UIImagePickerControllerDelegate, UINavigationControllerDelegate, 
                                                   CameraPreviewViewDelegate, Draw2SaveControllerDelegate, ImportControllerDelegate> {
    NSMutableArray *points;
    NSMutableData *data;  // this possibly not needed
    NSString *sessionID;
    NSString *userID;
    NSString *serverIP;
    NSDate *dateTime;
    NSTimer *timer;
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSOutputStream *imageOutStream;
    NSInputStream *imageInStream;
    NSOperationQueue* toServerQ;
    NSOperationQueue* fromServerQ;
    draw_mode_t mode;
    ui_color_t color;
    int readIndex;
    int pageIndex;
    network_op_t netOp;
    UIImage *imageToUpload;
    NSInteger fileSize;
    NSMutableData *rawData;
    NSInteger rawBytesRead;
    NSString *clientHost;
    NSInteger clientPort;
    NSMutableArray *markerArray;
    UIPopoverController *popOver;
    UIButton *pensil;
    NSMutableDictionary *lastPointFromUser;
    IBOutlet UIButton *connectionButton;
    Boolean connected; 
}

@property (nonatomic, retain) NSMutableArray *points;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSString *sessionID;
@property (nonatomic, copy) NSDate *dateTime;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSOutputStream *outputStream;
@property (nonatomic, retain) NSOutputStream *imageOutStream;
@property (nonatomic, retain) NSInputStream *imageInStream;
@property (nonatomic, retain) NSOperationQueue *toServerQ;
@property (nonatomic, retain) NSOperationQueue *fromServerQ;
@property (nonatomic, retain) NSString *userID;
@property (nonatomic, retain) NSString *serverIP;
@property (nonatomic, retain) UIImage *imageToUpload;
@property (nonatomic, retain) NSMutableData *rawData;
@property (nonatomic, retain) NSString *clientHost;
@property (nonatomic, retain) NSMutableArray *markerArray;
@property (nonatomic, retain) UIPopoverController *popOver;
@property (nonatomic, retain) NSMutableDictionary *lastPointFromUser;
@property (nonatomic, retain) IBOutlet UIButton *connectionButton;

//- (void) refreshView;
//- (IBAction) rePlay:(id)sender;
//- (IBAction) serializeData:(id)sender;
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
