//
//  Draw2ViewController.m
//  Draw2
//
//  Created by Billy Liang on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Draw2ViewController.h"
#import "ASIHTTPRequest.h"
#import "../JSON/SBJson.h"
#import "Draw2View.h"
#import "Draw2InputViewController.h"
#import "DrawContext.h"
#import "Draw2SaveController.h"
#import "CameraPreviewController.h"
#import "ImportViewController.h"

@implementation Draw2ViewController

@synthesize points;
@synthesize data;
@synthesize sessionID;
@synthesize dateTime;
@synthesize inputStream;
@synthesize outputStream;
@synthesize imageOutStream;
@synthesize imageInStream;
@synthesize toServerQ;
@synthesize fromServerQ;
@synthesize userID;
@synthesize serverIP;
@synthesize imageToUpload;
@synthesize rawData;
@synthesize clientHost;
@synthesize markerArray;
@synthesize popOver;
@synthesize lastPointFromUser;
@synthesize connectionButton;

- (void)dealloc
{
    [points release];
    [data release];
    [sessionID release];
    [dateTime release];
    [timer invalidate];
    [fromServerQ release];
    [toServerQ release];
    [lastPointFromUser release];
    [serverIP release];
    [sessionID release];
    [userID release];
    [inputStream close];
    [outputStream close];
    [inputStream release]; // if program crash upon exit, comment out this line
    [outputStream release]; // if program crash upon exit, comment out this line 
    if(markerArray != nil) {
        [markerArray release];
    }
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)initNetworkCommunication:(NSString *)ip_address withPort:(NSInteger)port role:(network_role_t)role
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSLog(@"server IP: %@, port: %d, role: %d", ip_address, port, role);
    /* don't need to enable read stream for sending screen shot */
    if (port != 8080) {
        /* schedule the stream socket on main runloop since the thread's runloop is short lived */
        if (role == HOST) {
            CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)ip_address, port, NULL, &writeStream);
            imageOutStream = (NSOutputStream *)writeStream;
            [imageOutStream setDelegate:self];
            [imageOutStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [imageOutStream open];
            NSLog(@"host connected");
        } else if (role == CLIENT) {
            CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)ip_address, port, &readStream, NULL);
            imageInStream = (NSInputStream *)readStream;
            [imageInStream setDelegate:self];
            [imageInStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [imageInStream open];
            NSLog(@"client connected");
        }
    } else {
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)ip_address, port, &readStream, &writeStream);
        inputStream = (NSInputStream *)readStream;
        outputStream = (NSOutputStream *)writeStream;
        [inputStream setDelegate:self];
        [outputStream setDelegate:self];
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inputStream open];
        [outputStream open];
    }
}

//- (void) drawUpdate:(NSMutableArray*)newPoints
- (void) drawUpdate:(DrawContext*)context
{
    Draw2View *drawView = (Draw2View*) self.view;
    [drawView updateView:context.dataPointArray withColor:context.colorString];
}

/* TODO: lots of object not freed in this function 
   make sure to release them during code clean up
 */
- (void) receiveDataFromServer:(NSString *)input
{
    int j, input_len;
    CGPoint point;
    NSValue *pointValue;
    NSString *userName;
    NSRange search_range, range, segment_range;
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    NSMutableArray *inputArray = [[NSMutableArray alloc] init];
    //NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    int index = 0;
    
    /* task to be run in NSOperation Queue */
    NSLog(@"server said: %@", input);
    input_len = [input length];
    
    //while (range.location != NSNotFound) {
    while (index < input_len) {
        search_range = NSMakeRange(index, input_len-index);
        range = [input rangeOfString:@"\n" options:0 range:search_range];
        
        segment_range = NSMakeRange(index, range.location - index);
        NSString *segment = [[NSString alloc] initWithString:[input substringWithRange:segment_range]];
        NSLog(@"separating into segment\n%@", segment);
        index = range.location + range.length;
        /*if (input_len - index <= 0)
            break;
        search_range = NSMakeRange(index, input_len-index);
         */
        //range = [input rangeOfString:@"\n" options:0 range:search_range];
        [inputArray addObject:segment];
        [segment release];
    }
    for (NSString *s in inputArray) {
        NSDictionary *dict = (NSDictionary *)[jsonParser objectWithString:s];
        [dict retain]; // TODO: do we need this retain here??
        if ([dict valueForKey:@"request"] != nil) {
            if ([[dict valueForKey:@"request"] isEqualToString:@"getState"]) {
                NSLog(@"received request to upload screen shot to server");
                /* get the port# then create a new socket to upload screen shot */
                if ([dict valueForKey:@"port"] != nil) {
                    NSString *portStr = [dict valueForKey:@"port"];
                    clientHost = [[dict valueForKey:@"clientHost"] retain];
                    clientPort = [[dict valueForKey:@"clientPort"] integerValue];
                    /* the order for creating socket and sending file size to server should not change */
                    [self initNetworkCommunication:self.serverIP withPort:[portStr intValue] role:HOST];
                } else {
                    NSLog(@"ERROR: malformed json string received");
                }
            } else if ([[dict valueForKey:@"request"] isEqualToString:@"returnState"]) {
                NSLog(@"received request to open socket to receive screen shot");
                if ([dict valueForKey:@"port"] != nil) {
                    NSString *portStr = [dict valueForKey:@"port"];
                    if ([dict valueForKey:@"length"] != nil) {
                        fileSize = [[dict valueForKey:@"length"] integerValue];
                    }
                    NSLog(@"new server port is %@, received file size: %d", portStr, fileSize);
                    /* connect to server to download background image, the order to open socket and send ACK cannot be changed */
                    [self initNetworkCommunication:self.serverIP withPort:[portStr intValue] role:CLIENT];
                } else {
                    NSLog(@"ERROR: malformed json string came in");
                }
            } else if ([[dict valueForKey:@"request"] isEqualToString:@"startSend"]) {
                //if ([dict valueForKey:@"user"] != nil) {
                //    NSString *name = [dict valueForKey:@"user"];
                //    if ([name isEqualToString:userName]) {
                        NSData *dataObj = UIImageJPEGRepresentation(imageToUpload, 1.0);
                        const uint8_t *buf = [dataObj bytes];
                        NSInteger size = [dataObj length];
                        NSLog(@"prepare to send %d bytes (image) to server", size);
                        NSInteger bytesWritten, total = 0;
                        while (size - total > 0) {
                            bytesWritten = [imageOutStream write:buf maxLength:size];
                            total += bytesWritten;
                            buf += bytesWritten;
                            NSLog(@"sent %d bytes", bytesWritten);
                        }
                        [imageOutStream close];
                        [imageOutStream release];
                //    } else {
                //        NSLog(@"ERROR: received ACK from different user");
                //    }
                //} else {
                //    NSLog(@"ERROR: malformed json string came in");
                //}
            } else if ([[dict valueForKey:@"request"] isEqualToString:@"error"]) {
                if ([dict valueForKey:@"error_code"] != nil) {
                    NSString *errorCodeStr = [dict valueForKey:@"reason"];
                    if ([errorCodeStr intValue] == ERROR_SESSION_EXISTED) {
                        NSLog(@"error - trying to start an existing session");
                        /* pop warning dialog then close the open sockets, may need to wipe the canvas clean too */
                        UIAlertView *alert;
                        alert = [[UIAlertView alloc] initWithTitle:nil message:@"Session already existed, please start another one" 
                                                     delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                        [alert show];
                        [alert release];
                        /* TODO: check if ios needs to send leaveSesion to server so server can close socket on their side 
                                 flex code does that, does the close socket on my side will be sufficient to alert the server
                         */
                        [connectionButton setImage:[UIImage imageNamed:@"disconnected"] forState:UIControlStateNormal];
                        connected = FALSE;
                        [inputStream close];
                        [outputStream close];
                        [inputStream release];
                        [outputStream release];
                    }
                } else {
                    NSLog(@"malformed json request");
                }
            } else if ([[dict valueForKey:@"request"] isEqualToString:@"updateData"]) {
                if ([dict valueForKey:@"user"] != nil) {
                    userName = [[dict valueForKey:@"user"] retain];  // TODO: retain probably not needed
                    if ([dict valueForKey:@"data"] != nil) {
                        NSString *colorStr = [dict valueForKey:@"color"];
                        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                        DrawContext *cxt = [[DrawContext alloc] init];
                        NSArray *dataArray = (NSArray *)[dict valueForKey:@"data"];
                        /* Add the last point receive previously if there is one to the array */
                        pointValue = [lastPointFromUser valueForKey:userName];
                        if (pointValue != nil) {
                            [tempArray addObject:pointValue];
                        }
                        NSLog(@"there are %d element in the array\n", [dataArray count]);
                        for (j = 0; j < [dataArray count]; j++) {
                            NSDictionary *element = (NSDictionary *)[dataArray objectAtIndex:j];
                            point.x = [[element valueForKey:@"x"] doubleValue];
                            point.y = [[element valueForKey:@"y"] doubleValue];
                            pointValue = [NSValue valueWithCGPoint:point];
                            [tempArray addObject:pointValue];
                        }
                        cxt.colorString = colorStr;
                        cxt.dataPointArray = tempArray;
                        [lastPointFromUser setValue:[tempArray lastObject] forKey:userName];
                        [tempArray release];
                        //[self.view drawRect:[self.view bounds]];
                        //[self performSelectorOnMainThread:@selector(drawUpdate:) withObject:tempArray waitUntilDone:NO];
                        [self performSelectorOnMainThread:@selector(drawUpdate:) withObject:cxt waitUntilDone:NO];
                        [cxt release];
                    }
                }
            }
        }
    }
    [inputArray release];
    [jsonParser release];
    NSLog(@"end of server said");
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent 
{
    int len;
    NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    
	switch (streamEvent) {
        case NSStreamEventHasBytesAvailable:
            if (theStream == inputStream) {
                /* allocate a page size, more than enough to hold a single update */
                uint8_t buffer[4096];  
                while ([inputStream hasBytesAvailable]) {
                    /* updates coming from the server */
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        /* TODO: check if input is retained by the nsoperation initWithTarget:selector:object function, if this is then need to release input */
                        NSString *input = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        if (nil != input) {
                            NSInvocationOperation* op = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(receiveDataFromServer:) object:input] autorelease];
                            [fromServerQ addOperation:op];
                        }
                    }
                }
            } else if (theStream == imageInStream) {
                if (!rawData) {
                    rawData = [[NSMutableData alloc] init];
                }
                /* okay to perform the receive function in the same thread, 
                   client can't do anything until it receives the background image
                 */
                uint8_t buffer[1024];  
                len = [imageInStream read:buffer maxLength:sizeof(buffer)];
                NSLog(@"received %d bytes from server", len);
                if (len > 0) {
                    [rawData appendBytes:(const void *)buffer length:len];
                    rawBytesRead += len;
                }
                if (rawBytesRead >= fileSize) {
                    /* we are done, update the view with image we just received */
                    NSLog(@"we are done, received total of %d bytes", rawBytesRead);
                    [self updateImageView:rawData];
                    [rawData release];
                }
            }
        break;
        case NSStreamEventOpenCompleted:
            if (theStream == imageOutStream) {
                NSLog(@"imageOutStream opened");
                //UIGraphicsBeginImageContext(self.view.frame.size);
                UIGraphicsBeginImageContext(self.view.bounds.size);
                //imageToUpload = [UIGraphicsGetImageFromCurrentImageContext() retain];
                Draw2View * drawView = (Draw2View*)self.view;
                imageToUpload = drawView.image;
                NSData *dataObj = UIImageJPEGRepresentation(imageToUpload, 1.0);
                NSInteger size = [dataObj length];
                /* send file size to the server */
                [jsonString appendString:@"{\"request\":\"ackGetState\", \"clientHost\":"];
                [jsonString appendFormat:@"\"%@\"", clientHost];
                [jsonString appendString:@", \"clientPort\": "];
                [jsonString appendFormat:@"%d", clientPort];
                [jsonString appendString:@", \"length\": "];
                [jsonString appendFormat:@"%d", size];
                [jsonString appendString:@", \"sessionID\": "];
                [jsonString appendFormat:@"\"%@\"", self.sessionID];
                [jsonString appendString:@"}\n"];
                NSLog(@"json string:\n%@", jsonString);
                NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
                NSLog(@"size of image to be uploaded is %d", size);
                [outputStream write:[jsonData bytes] maxLength:[jsonData length]];
                [jsonData release];
            } else if (theStream == imageInStream) {
                NSLog(@"imageInStream opened");
                /* send ACK */
                [jsonString appendString:@"{\"request\":\"ackReturnState\""];
                [jsonString appendString:@", \"sessionID\": "];
                [jsonString appendFormat:@"\"%@\"", self.sessionID];
                [jsonString appendString:@"}\n"];
                NSLog(@"json string:\n%@", jsonString);
                NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
                [outputStream write:[jsonData bytes] maxLength:[jsonData length]];
                [jsonData release];
            } else if (theStream == inputStream) {
                NSLog(@"inutStream is opened");
                /* TODO:
                 1. change the connection icon to connect 
                 */
                
            } else if (theStream == outputStream) {
                NSLog(@"outputStream is opened");
            }
        break;
        case NSStreamEventErrorOccurred:
            NSLog(@"Socket error string: %@", [[theStream streamError] localizedDescription]);
            if (theStream == outputStream || theStream == inputStream) {
                connected = FALSE;
                [connectionButton setImage:[UIImage imageNamed:@"disconnected"] forState:UIControlStateNormal];
                [inputStream close];
                [outputStream close];
            }
        break;
    }
    [jsonString release];
}

- (void) updateImageView:(NSData *)imageData 
{
    Draw2View * imgView;
    //UIImage *img = [[UIImage alloc] initWithContentsOfFile:@"/Users/biliang/Documents/test.jpg"];
    UIImage *img = [[UIImage alloc] initWithData:imageData];
    imgView = (Draw2View *)self.view;
    imgView.image = img;
    
    /* can start drawing */
    mode = DRAW;
    [img release];
    [imageInStream close];
    [imageInStream release];
}

- (void) uploadTask
{
    int size, i, max_range;
    ui_color_t color_value;
    CGPoint point;
    NSMutableString *coordValues = [[NSMutableString alloc] initWithCapacity:20];
    NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    
    size = [points count];
    //NSLog(@"sending coordinates from index %d to %d", readIndex, size);
    if (size > readIndex) {
        /* due to array indexing we always get one last end of line delimiter in
           this calculation, so if size - readIndex is equal to 1, that could be
           the delimiter, don't need to send if that's the case
         */
        if (size - readIndex == 1) {
            point = [[points objectAtIndex:readIndex] CGPointValue];
            if (point.x == -1.0 && point.y == -1.0) {
                readIndex++; // skip over this one, so the new line starts off correctly
                return;
            }
        }
        /* use the current color scheme */
        if ([markerArray count] == 0) {
            /* there are points to send */
            if (size - readIndex >= 15) {
                max_range = readIndex + 15;
            } else {
                max_range = size;
            }
            color_value = [self getColor];
        } else {
            /* always get the first element, since it will be pop after it's done */
            NSValue *value = [markerArray objectAtIndex:0];
            color_marker_t marker;
            [value getValue:&marker];
            color_value = marker.color;
            if (marker.boundary - readIndex >= 15) {
                max_range = readIndex + 15;
            } else {
                max_range = marker.boundary;
                [markerArray removeObjectAtIndex:0];
            }
        }
        for (i = readIndex; i < max_range; i++) {
            if (i > readIndex) {
                [coordValues appendString:@", "];
            }
            point = [[points objectAtIndex:i] CGPointValue];
            [coordValues appendString:@"{\"x\":"];
            [coordValues appendString:[NSString stringWithFormat:@"%f, ", point.x]];
            [coordValues appendString:@"\"y\":"];
            [coordValues appendString:[NSString stringWithFormat:@"%f", point.y]];
            [coordValues appendString:@"}"];
        }
        [jsonString appendString:@"{\"request\":\"updateData\", \"user\":"];
        [jsonString appendFormat:@"\"%@\"", self.userID];
        [jsonString appendString:@", \"color\": "];
        [jsonString appendFormat:@"\"%@\"", [self getColorScheme:color_value]];
        //[jsonString appendString:@", \"range\": "];
        //[jsonString appendFormat:@"\"%d - %d\"", readIndex, max_range];
        //[jsonString appendString:[NSString stringWithFormat:@"%f", [dateTime timeIntervalSinceReferenceDate]]];
        //[jsonString appendFormat:@"%f", [dateTime timeIntervalSinceReferenceDate]];
        [jsonString appendString:@", \"sessionID\": "];
        [jsonString appendFormat:@"\"%@\"", self.sessionID];
        [jsonString appendString:@", \"data\": ["];
        [jsonString appendString:coordValues];
        [jsonString appendString:@"]}\n"];
        NSLog(@"json string:\n%@", jsonString);
        NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[jsonData bytes] maxLength:[jsonData length]];
        readIndex = max_range - 1;
    }
    [coordValues release];
    [jsonString release];
}

// timer function to send coordinate points to the server
- (void)sendCoordinates:(NSTimer*)theTimer
{
    if (connected) {
        NSInvocationOperation* op = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(uploadTask) object:nil] autorelease];
    
        [toServerQ addOperation:op];
    }
    
#if 0    
    size = [points count];
    if (size > readIndex) {
        /* there are points to send */
        for (i = readIndex; i < size; i++) {
            if (i > 0) {
                [coordValues appendString:@", "];
            }
            point = [[points objectAtIndex:i] CGPointValue];
            [coordValues appendString:@"{\"x\":"];
            [coordValues appendString:[NSString stringWithFormat:@"%f, ", point.x]];
            [coordValues appendString:@"\"y\":"];
            [coordValues appendString:[NSString stringWithFormat:@"%f", point.y]];
            [coordValues appendString:@"}"];
        }
        //[jsonString appendString:@"{\"timestamp\": "];
        //[jsonString appendString:[NSString stringWithFormat:@"%f", [dateTime timeIntervalSinceReferenceDate]]];
        //[jsonString appendFormat:@"%f", [dateTime timeIntervalSinceReferenceDate]];
        [jsonString appendString:@", \"sessionID\": "];
        [jsonString appendFormat:@"\"%@\"", sessionID];
        [jsonString appendString:@", \"data\": ["];
        [jsonString appendString:coordValues];
        [jsonString appendString:@"]}"];
        NSLog(@"json string:\n%@", jsonString);
        NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[jsonData bytes] maxLength:[jsonData length]];
        readIndex = size;
    }
#endif
}


- (void) viewWillAppear:(BOOL)animated 
{
    CGAffineTransform xform = CGAffineTransformMakeRotation(M_PI/2.0);
    self.view.transform = xform;
    CGRect contentRect = CGRectMake(0,0, 1024, 768);
	self.view.bounds = contentRect;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    // calculate new center point
    /*CGFloat x = self.view.bounds.size.width / 2.0;
    CGFloat y = self.view.bounds.size.height / 2.0;
    CGPoint center = CGPointMake(y, x);
    NSLog(@"center.x = %f, center.y = %f", x, y);
    
    // set the new center point
    self.view.center = center;
    */
#if 0
    //self.view.transform = CGAffineTransformIdentity;
    //CGAffineTransform transform = self.view.transform;
    //transform = CGAffineTransformRotate(transform, (M_PI / 2.0));
    CGAffineTransform xform = CGAffineTransformMakeRotation(degreesToRadians(90));
    self.view.transform = xform;
    //self.view.transform = transform;
    
    
    CGRect contentRect = CGRectMake(0, 0, 1024, 768);
	self.view.bounds = contentRect;
#endif    
    pageIndex = 0;
    mode = DRAW; 
    color = BLACK;
    netOp = NONE;
    lastPointFromUser = [[NSMutableDictionary alloc] init];
    points = [[NSMutableArray alloc] init];
    data = [[NSMutableData data] init];
    //sessionID = [[NSString alloc] init];
    toServerQ = [[NSOperationQueue alloc] init];
    fromServerQ = [[NSOperationQueue alloc] init];
    readIndex = 0;
    rawBytesRead = 0;
    connected = FALSE;
    //SEL sendCoordinates = @selector(sendCoordinates:);
    /* put network i/o code here for now, may not be 
       the best location.  TODO: If connection to  
       server droped, needs a way to reconnect
     */
    //[self initNetworkCommunication];
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:sendCoordinates userInfo:nil repeats:TRUE];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        NSLog(@"In landscape right mode");
        return YES;
    } 
     
    return NO;
}

/*
- (void) refreshView
{
    NSLog(@"into refreshView");
    //[self.view setNeedsDisplay];
    [self.view drawRect:[self.view bounds]];
}

- (IBAction) rePlay:(id)sender
{
    int i;
    CGPoint point;
    NSKeyedUnarchiver *unarchiver;
    
    unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    points = [[unarchiver decodeObjectForKey:@"drawingPath"] retain];
    [unarchiver finishDecoding];
    [unarchiver release];
    NSLog(@"there are %d points in the array\n", [points count]);
    
    for (i = 0; i < [points count]; i++) {
        point = [[points objectAtIndex:i] CGPointValue];
        NSLog(@"%f,%f, ", point.x, point.y);
    }
    [self.view drawRect:[self.view bounds]];
}

- (IBAction) serializeData:(id)sender
{
    NSKeyedArchiver *archiver;
    
    if (points) {
        //data = [NSMutableData data];
        archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:points forKey:@"drawingPath"];
        [archiver finishEncoding];
        [archiver release];
        [points removeAllObjects];
        
        NSLog(@"there are %d points in the array\n", [points count]);
        [self.view drawRect:[self.view bounds]];
    }
}
*/

- (void) userInputFinish:(NSString *)server_ip 
         withSessionID:(NSString *)session_id 
         withUserName:(NSString *)user_name
         isConfirm:(Boolean)confirm
{
    int length;
    NSMutableString *jsonString;
    
    if (confirm) {
        serverIP = server_ip;
        sessionID = session_id;
        userID = user_name;
        
        /* change the icon to connected, assuming network connection will succeed 
           if socket connection failed, error condition will be captured by socket
           event, the icon will be reversed back to disconnected
         */
        connected = TRUE;
        [connectionButton setImage:[UIImage imageNamed:@"connected"] forState:UIControlStateNormal];
        [self initNetworkCommunication:self.serverIP withPort:8080 role:GENERAL];
        if (netOp == START_SESSION) {
            jsonString = [[NSMutableString alloc] initWithString:@"{\"request\":\"startSession\", \"user\":"];
            [jsonString appendFormat:@"\"%@\"", self.userID];
            [jsonString appendString:@", \"sessionID\": "];
            [jsonString appendFormat:@"\"%@\"}", self.sessionID];
        } else if (netOp == JOIN_SESSION) {
            jsonString = [[NSMutableString alloc] initWithString:@"{\"request\":\"joinSession\", \"user\":"];
            [jsonString appendFormat:@"\"%@\"", self.userID];
            [jsonString appendString:@", \"sessionID\": "];
            [jsonString appendFormat:@"\"%@\"}", self.sessionID];
        }
        if (connected) {
            NSLog(@"debug: stream status %d", [outputStream streamStatus]);
            NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
            length = [outputStream write:[jsonData bytes] maxLength:[jsonData length]];
            if (length < 0) {
                /* something wrong with the socket connection, exit */
                connected = FALSE;
                [outputStream close];
                [inputStream close];
                [inputStream release];
                [outputStream release];
                [connectionButton setImage:[UIImage imageNamed:@"disconnected"] forState:UIControlStateNormal];
                [self dismissModalViewControllerAnimated:YES];
                UIAlertView *alert;
                alert = [[UIAlertView alloc] initWithTitle:nil message:@"Network connection failed,\nplease try again"
                                             delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                [alert release];
                return;
            }
            if (netOp == START_SESSION) {
                mode = DRAW;
            }
            SEL sendCoordinates = @selector(sendCoordinates:);
            timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:sendCoordinates userInfo:nil repeats:TRUE];
            netOp = NONE;
            [jsonData release];
        }
        if(jsonString != nil) {
            [jsonString release];
        }
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction) startSession:(id)sender
{
/*
    NSURL *url = [NSURL URLWithString:@"http://localhost:8888/draw/startSession?userID=tester"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setRequestMethod:@"GET"];
    [request setDelegate:self];
    [request startAsynchronous];
*/
    Draw2InputViewController *modalView = [[Draw2InputViewController alloc] init];
    modalView.delegate = self;
    modalView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    modalView.modalPresentationStyle = UIModalPresentationFormSheet;
    netOp = START_SESSION;
    [self presentModalViewController:modalView animated:YES];
    [modalView release];
}

- (IBAction) joinSession:(id)sender
{
    Draw2InputViewController *modalView = [[Draw2InputViewController alloc] init];
    modalView.delegate = self;
    modalView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    modalView.modalPresentationStyle = UIModalPresentationFormSheet;
    netOp = JOIN_SESSION;
    [self presentModalViewController:modalView animated:YES];
    [modalView release];
}

- (IBAction) sendPoints:(id)sender
{
    int i;
    CGPoint point;
    NSMutableString *coordValues = [[NSMutableString alloc] initWithCapacity:20];
    NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    dateTime = [[NSDate alloc] init];
    
    NSLog(@"dateTime native representation: %f", [dateTime timeIntervalSinceReferenceDate]);
    for (i = 0; i < [points count]; i++) {
        if (i > 0) {
            [coordValues appendString:@", "];
        }
        point = [[points objectAtIndex:i] CGPointValue];
        [coordValues appendString:@"{\"x\":"];
        [coordValues appendString:[NSString stringWithFormat:@"%f, ", point.x]];
        [coordValues appendString:@"\"y\":"];
        [coordValues appendString:[NSString stringWithFormat:@"%f", point.y]];
        [coordValues appendString:@"}"];
    }
    [jsonString appendString:@"{\"timestamp\": "];
    //[jsonString appendString:[NSString stringWithFormat:@"%f", [dateTime timeIntervalSinceReferenceDate]]];
    [jsonString appendFormat:@"%f", [dateTime timeIntervalSinceReferenceDate]];
    [jsonString appendString:@", \"sessionID\": "];
    [jsonString appendFormat:@"\"%@\"", sessionID];
    [jsonString appendString:@", \"data\": ["];
    [jsonString appendString:coordValues];
    [jsonString appendString:@"]}"];
    NSLog(@"json string:\n%@", jsonString);
    
    NSURL *url = [NSURL URLWithString:@"http://localhost:8888/draw/postData"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request appendPostData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setDelegate:self];
    [request startAsynchronous];
    
    /* clear points here, get the points from server to reconstruct the whole drawing */
    NSLog(@"sending %d points to the server\n", [points count]);
    [points removeAllObjects];
    [self.view drawRect:[self.view bounds]];
    [coordValues release];
    [jsonString release];
    [dateTime release];
}

- (IBAction) getPoints:(id)sender
{
    NSMutableString *URL = [[NSMutableString alloc] initWithString:@"http://localhost:8888/draw/getAllData?sessionID="];
    [URL appendString:sessionID];
    [URL appendFormat:@"&timestamp=%f", [dateTime timeIntervalSinceReferenceDate]];
    NSLog(@"GET URL: %@", URL);
    NSURL *url = [NSURL URLWithString:URL];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setRequestMethod:@"GET"];
    [request setDelegate:self];
    [request startAsynchronous];
    [URL release];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    int i, j;
    CGPoint point;
    NSValue *pointValue;
    // Use when fetching text data
    SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
    NSString *responseString = [request responseString];
    NSLog(@"received http response: %@", responseString);
    NSDictionary *dict = (NSDictionary *)[jsonParser objectWithString:responseString];
    if ([dict valueForKey:@"sessionID"] != nil) {
        sessionID = [[dict valueForKey:@"sessionID"] retain];
    }
    NSLog(@"sessionID = %@", sessionID);
    if ([dict valueForKey:@"data"] != nil) {
        NSArray *dataArray = (NSArray *)[dict valueForKey:@"data"];
        for (j = 0; j < [dataArray count]; j++) {
            NSDictionary *element = (NSDictionary *)[dataArray objectAtIndex:j];
            NSArray *coordArray = [element valueForKey:@"data"];
            NSLog(@"there are %d element in the array\n", [coordArray count]);
            for (i = 0; i < [coordArray count]; i++) {
                NSDictionary *coordinatePt = (NSDictionary *)[coordArray objectAtIndex:i];
                point.x = [[coordinatePt valueForKey:@"x"] doubleValue];
                point.y = [[coordinatePt valueForKey:@"y"] doubleValue];
                pointValue = [NSValue valueWithCGPoint:point];
                [points addObject:pointValue];
                NSLog(@"%f, %f", [pointValue CGPointValue].x, [pointValue CGPointValue].y);
            }
        }
        [self.view drawRect:[self.view bounds]];
    }
    [jsonParser release];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSLog(@"http request return error, error description: %@", [error localizedDescription]);
}

-(void) disMissSaveDialog 
{
    if (popOver != nil) {
        [popOver dismissPopoverAnimated:NO];
        //[popOver release];
    }
}

-(void) disMissImportDialog 
{
    if (popOver != nil) {
        [popOver dismissPopoverAnimated:NO];
        //[popOver release];
    }
}

-(IBAction) saveDrawing:(id)sender
{
    CGFloat height;
    UIButton *saveButton = (UIButton *)sender;
    Draw2View * myView = (Draw2View *)self.view;
    Draw2SaveController *saveController = [[Draw2SaveController alloc] initWithStyle:UITableViewStylePlain];
    saveController.delegate = self;
    [saveController sendPictureToView:myView.image];
    popOver = [[UIPopoverController alloc] initWithContentViewController:saveController];
    //[saveController release];  <-- figure out why release here causes a crash
    height = 40 * 2; // 2 is the number of rows we have for this pop up
    popOver.popoverContentSize = CGSizeMake(240, height);
    /*
    [popOver presentPopoverFromRect:CGRectMake(saveButton.frame.origin.x + saveButton.frame.size.width, (saveButton.frame.origin.y*2 + saveButton.frame.size.height)/2, 1, 1) 
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionLeft 
                           animated:YES];
     */
    [popOver presentPopoverFromRect:saveButton.frame 
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionAny 
                           animated:YES];
}

- (IBAction) deleteDrawing:(id)sender
{
    Draw2View *imgView;
    
    /* clean the canvas, remove all array points and bg image */
    [points removeAllObjects];
    [lastPointFromUser removeAllObjects];
    [markerArray removeAllObjects]; 
    imgView = (Draw2View *)self.view;
    imgView.image = nil;
}

-(IBAction) takePicture:(id)sender
{
    CGFloat height;
    UIButton *importButton = (UIButton *)sender;
    ImportViewController *importController = [[ImportViewController alloc] initWithStyle:UITableViewStylePlain];
    importController.parent = self;
    importController.delegate = self;
    popOver = [[UIPopoverController alloc] initWithContentViewController:importController];
    height = 40*2;
    popOver.popoverContentSize = CGSizeMake(240, height);
    [popOver presentPopoverFromRect:importButton.frame 
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionAny 
                           animated:YES];
#if 0
    CameraPreviewController *cameraView = [[CameraPreviewController alloc] init];
    cameraView.delegate = self;
    [self presentModalViewController:cameraView animated:YES];
    [cameraView release];
#endif
}

- (void) cameraCaptureDidFinished:(UIImage *)capturedImage
{
    Draw2View * imgView;
    imgView = (Draw2View *)self.view;
    imgView.image = capturedImage;
    
#if 0
    CGSize size = capturedImage.size;
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextRotateCTM(context, M_PI/2.0);
    //CGContextTranslateCTM( context, 0.5f * size.width, 0.5f * size.height ) ;
    
    //[imgView.image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    [imgView.image drawAtPoint:CGPointMake(0.0, 0.0)];
    UIGraphicsEndImageContext();
#endif
    NSLog(@"image orientation displayed on screen is %d", [imgView.image imageOrientation]);
    //[self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    Draw2View * imgView;
    UIImage *photo = [[info valueForKey:UIImagePickerControllerOriginalImage] retain];
    imgView = (Draw2View *)self.view;
    imgView.image = photo;
    
    // need to find a better place for the following lines due to loading image from photo album using ImportViewController class
    /*
    [popOver dismissPopoverAnimated:NO];
    [popOver release];
     */
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    //[self dismissModalViewControllerAnimated:YES];
    [popOver dismissPopoverAnimated:NO];
    [popOver release];
}

- (IBAction) setColor:(id)sender
{
    int number;
    ui_color_t old_color;
    UIButton *button = (UIButton *)sender;
    
    if (!markerArray) {
        markerArray = [[NSMutableArray alloc] init];
    }
    old_color = [self getColor];
    if ([button.titleLabel.text isEqualToString:@"Black"]) {
        color = BLACK;
        NSLog(@"Changing color to black");
    } else if ([button.titleLabel.text isEqualToString:@"Green"]) {
        color = GREEN;
        NSLog(@"Changing color to green");
    } else if ([button.titleLabel.text isEqualToString:@"Red"]) {
        color = RED;
        NSLog(@"Changing color to red");
    } else if ([button.titleLabel.text isEqualToString:@"Blue"]) {
        color = BLUE;
        NSLog(@"Changing color to blue");
    } 
    number = [points count];
    if (number > 0) { // color changed, record the last point where old color was used
        color_marker_t marker;
        marker.color = old_color;
        marker.boundary = number;
        NSValue *value = [NSValue valueWithBytes:&marker objCType:@encode(color_marker_t)];
        [markerArray addObject:value];
    }
}

- (ui_color_t) getColor
{
    return color;
}

- (NSString *) getColorScheme:(ui_color_t)colorValue
{
    if (colorValue == RED) {
        return @"RED";
    } else if (colorValue == GREEN) {
        return @"GREEN";
    } else if (colorValue == BLUE) {
        return @"BLUE";
    } else {
        return @"BLACK";
    }
}

- (IBAction) setEdittingMode:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    if ([button.titleLabel.text isEqualToString:@"Edit"]) {
        mode = DRAW;
        NSLog(@"Changing to editing mode");
    } else if ([button.titleLabel.text isEqualToString:@"Erase"]) {
        mode = ERASE;
        NSLog(@"Changing to erasing mode");
    }
}

- (void) setMode:(draw_mode_t)drawingMode
{
    mode = drawingMode;
}

- (draw_mode_t) getMode
{
    return mode;
}

- (Boolean) isConnected
{
    return connected;
}

@end
