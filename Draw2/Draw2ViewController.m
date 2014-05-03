//
//  Draw2ViewController.m
//  Draw2
//
//  Created by Billy Liang on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Draw2ViewController.h"
#import "Draw2View.h"
#import "Draw2InputViewController.h"
#import "DrawContext.h"
#import "Draw2SaveController.h"
#import "CameraPreviewController.h"
#import "ImportViewController.h"
#import "AFHTTPRequestOperationManager.h"

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
    
    NSLog(@"server IP: %@, port: %ld, role: %d", ip_address, (long)port, role);
    /* don't need to enable read stream for sending screen shot */
    if (port != 8080) {
        /* schedule the stream socket on main runloop since the thread's runloop is short lived */
        if (role == HOST) {
            CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip_address, (UInt32)port, NULL, &writeStream);
            self.imageOutStream = (__bridge NSOutputStream *)writeStream;
            [self.imageOutStream setDelegate:self];
            [self.imageOutStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [self.imageOutStream open];
            NSLog(@"host connected");
        } else if (role == CLIENT) {
            CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip_address, (UInt32)port, &readStream, NULL);
            self.imageInStream = (__bridge NSInputStream *)readStream;
            [self.imageInStream setDelegate:self];
            [self.imageInStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [self.imageInStream open];
            NSLog(@"client connected");
        }
    } else {
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)ip_address, (UInt32)port, &readStream, &writeStream);
        self.inputStream = (__bridge NSInputStream *)readStream;
        self.outputStream = (__bridge NSOutputStream *)writeStream;
        [self.inputStream setDelegate:self];
        [self.outputStream setDelegate:self];
        [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream open];
        [self.outputStream open];
    }
}

//- (void) drawUpdate:(NSMutableArray*)newPoints
- (void) drawUpdate:(DrawContext*)context
{
    Draw2View *drawView = (Draw2View*) self.view;
    [drawView updateView:context.dataPointArray withColor:context.colorString];
}

- (void)receiveDataFromServer:(NSString *)input
{
    NSInteger j, input_len;
    CGPoint point;
    NSValue *pointValue;
    NSString *userName;
    NSRange search_range, range, segment_range;
    NSMutableArray *inputArray = [[NSMutableArray alloc] init];
    //NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    NSInteger index = 0;
    
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
    }
    for (NSString *s in inputArray) {
		uint8_t buffer[4096];
		NSUInteger usedLength;
		NSRange range = NSMakeRange(0, [s length]);
		[s getBytes:buffer maxLength:4096 usedLength:&usedLength encoding:NSUTF8StringEncoding options:NSStringEncodingConversionAllowLossy range:range remainingRange:NULL];
		NSData *jsonData = [NSData dataWithBytes:buffer length:usedLength];
		NSError *error;
		NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)[NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error]];
        if ([dict valueForKey:@"request"] != nil) {
            if ([[dict valueForKey:@"request"] isEqualToString:@"getState"]) {
                NSLog(@"received request to upload screen shot to server");
                /* get the port# then create a new socket to upload screen shot */
                if ([dict valueForKey:@"port"] != nil) {
                    NSString *portStr = [dict valueForKey:@"port"];
                    self.clientHost = [dict valueForKey:@"clientHost"];
                    self.clientPort = [[dict valueForKey:@"clientPort"] integerValue];
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
                        self.fileSize = [[dict valueForKey:@"length"] integerValue];
                    }
                    NSLog(@"new server port is %@, received file size: %ld", portStr, (long)self.fileSize);
                    /* connect to server to download background image, the order to open socket and send ACK cannot be changed */
                    [self initNetworkCommunication:self.serverIP withPort:[portStr intValue] role:CLIENT];
                } else {
                    NSLog(@"ERROR: malformed json string came in");
                }
            } else if ([[dict valueForKey:@"request"] isEqualToString:@"startSend"]) {
                //if ([dict valueForKey:@"user"] != nil) {
                //    NSString *name = [dict valueForKey:@"user"];
                //    if ([name isEqualToString:userName]) {
                        NSData *dataObj = UIImageJPEGRepresentation(self.imageToUpload, 1.0);
                        const uint8_t *buf = [dataObj bytes];
                        NSInteger size = [dataObj length];
                        NSLog(@"prepare to send %ld bytes (image) to server", (long)size);
                        NSInteger bytesWritten, total = 0;
                        while (size - total > 0) {
                            bytesWritten = [imageOutStream write:buf maxLength:size];
                            total += bytesWritten;
                            buf += bytesWritten;
                            NSLog(@"sent %ld bytes", (long)bytesWritten);
                        }
                        [self.imageOutStream close];
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
                        /* TODO: check if ios needs to send leaveSesion to server so server can close socket on their side
                                 flex code does that, does the close socket on my side will be sufficient to alert the server
                         */
                        [connectionButton setImage:[UIImage imageNamed:@"disconnected"] forState:UIControlStateNormal];
                        self.connected = FALSE;
                        [self.inputStream close];
                        [self.outputStream close];
                    }
                } else {
                    NSLog(@"malformed json request");
                }
            } else if ([[dict valueForKey:@"request"] isEqualToString:@"updateData"]) {
                if ([dict valueForKey:@"user"] != nil) {
                    userName = [dict valueForKey:@"user"];
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
                        NSLog(@"there are %lu element in the array\n", (unsigned long)[dataArray count]);
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
                        //[self.view drawRect:[self.view bounds]];
                        //[self performSelectorOnMainThread:@selector(drawUpdate:) withObject:tempArray waitUntilDone:NO];
                        [self performSelectorOnMainThread:@selector(drawUpdate:) withObject:cxt waitUntilDone:NO];
                    }
                }
            }
        }
    }
    NSLog(@"end of server said");
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent 
{
    NSInteger len;
    NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    
	switch (streamEvent) {
        case NSStreamEventHasBytesAvailable:
            if (theStream == self.inputStream) {
                /* allocate a page size, more than enough to hold a single update */
                uint8_t buffer[4096];  
                while ([self.inputStream hasBytesAvailable]) {
                    /* updates coming from the server */
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        /* TODO: check if input is retained by the nsoperation initWithTarget:selector:object function, if this is then need to release input */
                        NSString *input = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        if (nil != input) {
                            NSInvocationOperation* op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(receiveDataFromServer:) object:input];
                            [self.fromServerQ addOperation:op];
                        }
                    }
                }
            } else if (theStream == self.imageInStream) {
                if (!self.rawData) {
                    self.rawData = [[NSMutableData alloc] init];
                }
                /* okay to perform the receive function in the same thread, 
                   client can't do anything until it receives the background image
                 */
                uint8_t buffer[1024];  
                len = [self.imageInStream read:buffer maxLength:sizeof(buffer)];
                NSLog(@"received %ld bytes from server", (long)len);
                if (len > 0) {
                    [self.rawData appendBytes:(const void *)buffer length:len];
                    self.rawBytesRead += len;
                }
                if (self.rawBytesRead >= self.fileSize) {
                    /* we are done, update the view with image we just received */
                    NSLog(@"we are done, received total of %ld bytes", (long)self.rawBytesRead);
                    [self updateImageView:self.rawData];
                }
            }
        break;
        case NSStreamEventOpenCompleted:
            if (theStream == self.imageOutStream) {
                NSLog(@"imageOutStream opened");
                //UIGraphicsBeginImageContext(self.view.frame.size);
                UIGraphicsBeginImageContext(self.view.bounds.size);
                //imageToUpload = [UIGraphicsGetImageFromCurrentImageContext() retain];
                Draw2View * drawView = (Draw2View*)self.view;
                self.imageToUpload = drawView.image;
                NSData *dataObj = UIImageJPEGRepresentation(self.imageToUpload, 1.0);
                NSInteger size = [dataObj length];
                /* send file size to the server */
                [jsonString appendString:@"{\"request\":\"ackGetState\", \"clientHost\":"];
                [jsonString appendFormat:@"\"%@\"", self.clientHost];
                [jsonString appendString:@", \"clientPort\": "];
                [jsonString appendFormat:@"%ld", (long)self.clientPort];
                [jsonString appendString:@", \"length\": "];
                [jsonString appendFormat:@"%ld", (long)size];
                [jsonString appendString:@", \"sessionID\": "];
                [jsonString appendFormat:@"\"%@\"", self.sessionID];
                [jsonString appendString:@"}\n"];
                NSLog(@"json string:\n%@", jsonString);
                NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
                NSLog(@"size of image to be uploaded is %ld", (long)size);
                [self.outputStream write:[jsonData bytes] maxLength:[jsonData length]];
            } else if (theStream == self.imageInStream) {
                NSLog(@"imageInStream opened");
                /* send ACK */
                [jsonString appendString:@"{\"request\":\"ackReturnState\""];
                [jsonString appendString:@", \"sessionID\": "];
                [jsonString appendFormat:@"\"%@\"", self.sessionID];
                [jsonString appendString:@"}\n"];
                NSLog(@"json string:\n%@", jsonString);
                NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
                [self.outputStream write:[jsonData bytes] maxLength:[jsonData length]];
            } else if (theStream == self.inputStream) {
                NSLog(@"inutStream is opened");
                /* TODO:
                 1. change the connection icon to connect 
                 */
                
            } else if (theStream == self.outputStream) {
                NSLog(@"outputStream is opened");
            }
        break;
        case NSStreamEventErrorOccurred:
            NSLog(@"Socket error string: %@", [[theStream streamError] localizedDescription]);
            if (theStream == self.outputStream || theStream == self.inputStream) {
                self.connected = FALSE;
                [self.connectionButton setImage:[UIImage imageNamed:@"disconnected"] forState:UIControlStateNormal];
                [self.inputStream close];
                [self.outputStream close];
            }
        default:
            break;
        break;
    }
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
    [self.imageInStream close];
}

- (void) uploadTask
{
    NSInteger size, i, max_range;
    ui_color_t color_value;
    CGPoint point;
    NSMutableString *coordValues = [[NSMutableString alloc] initWithCapacity:20];
    NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    
    size = [self.points count];
    //NSLog(@"sending coordinates from index %d to %d", readIndex, size);
    if (size > self.readIndex) {
        /* due to array indexing we always get one last end of line delimiter in
           this calculation, so if size - readIndex is equal to 1, that could be
           the delimiter, don't need to send if that's the case
         */
        if (size - self.readIndex == 1) {
            point = [[self.points objectAtIndex:self.readIndex] CGPointValue];
            if (point.x == -1.0 && point.y == -1.0) {
                self.readIndex++; // skip over this one, so the new line starts off correctly
                return;
            }
        }
        /* use the current color scheme */
        if ([markerArray count] == 0) {
            /* there are points to send */
            if (size - self.readIndex >= 15) {
                max_range = self.readIndex + 15;
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
            if (marker.boundary - self.readIndex >= 15) {
                max_range = self.readIndex + 15;
            } else {
                max_range = marker.boundary;
                [markerArray removeObjectAtIndex:0];
            }
        }
        for (i = self.readIndex; i < max_range; i++) {
            if (i > self.readIndex) {
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
        [self.outputStream write:[jsonData bytes] maxLength:[jsonData length]];
        self.readIndex = max_range - 1;
    }
}

// timer function to send coordinate points to the server
- (void)sendCoordinates:(NSTimer*)theTimer
{
    if (self.connected) {
        NSInvocationOperation* op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(uploadTask) object:nil];
    
        [self.toServerQ addOperation:op];
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
    self.pageIndex = 0;
    mode = DRAW; 
    color = BLACK;
    netOp = NONE;
    self.lastPointFromUser = [[NSMutableDictionary alloc] init];
    self.points = [[NSMutableArray alloc] init];
    self.data = [[NSMutableData data] init];
    //sessionID = [[NSString alloc] init];
    self.toServerQ = [[NSOperationQueue alloc] init];
    self.fromServerQ = [[NSOperationQueue alloc] init];
    self.readIndex = 0;
    self.rawBytesRead = 0;
    self.connected = FALSE;
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
    NSInteger length;
    NSMutableString *jsonString;
    
    if (confirm) {
        self.serverIP = server_ip;
        self.sessionID = session_id;
        self.userID = user_name;
        
        /* change the icon to connected, assuming network connection will succeed 
           if socket connection failed, error condition will be captured by socket
           event, the icon will be reversed back to disconnected
         */
        self.connected = TRUE;
        [self.connectionButton setImage:[UIImage imageNamed:@"connected"] forState:UIControlStateNormal];
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
        if (self.connected) {
            NSData *jsonData = [[NSData alloc] initWithData:[jsonString dataUsingEncoding:NSASCIIStringEncoding]];
            length = [self.outputStream write:[jsonData bytes] maxLength:[jsonData length]];
            if (length < 0) {
                /* something wrong with the socket connection, exit */
                self.connected = FALSE;
                [self.outputStream close];
                [self.inputStream close];
                [self.connectionButton setImage:[UIImage imageNamed:@"disconnected"] forState:UIControlStateNormal];
                [self dismissViewControllerAnimated:YES completion:^{
                    UIAlertView *alert;
                    alert = [[UIAlertView alloc] initWithTitle:nil message:@"Network connection failed,\nplease try again"
                                                      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                }];
                return;
            }
            if (netOp == START_SESSION) {
                mode = DRAW;
            }
            SEL sendCoordinates = @selector(sendCoordinates:);
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:sendCoordinates userInfo:nil repeats:TRUE];
            netOp = NONE;
        }
    }
    [self dismissViewControllerAnimated:YES completion:^{
    }];
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
    [self presentViewController:modalView animated:YES completion:^{
    }];
}

- (IBAction)joinSession:(id)sender
{
    Draw2InputViewController *modalView = [[Draw2InputViewController alloc] init];
    modalView.delegate = self;
    modalView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    modalView.modalPresentationStyle = UIModalPresentationFormSheet;
    netOp = JOIN_SESSION;
    [self presentViewController:modalView animated:YES completion:^{
    }];
}

- (IBAction)sendPoints:(id)sender
{
    int i;
    CGPoint point;
    NSMutableString *coordValues = [[NSMutableString alloc] initWithCapacity:20];
    NSMutableString *jsonString = [[NSMutableString alloc] initWithCapacity:40];
    self.dateTime = [[NSDate alloc] init];
    
    NSLog(@"dateTime native representation: %f", [self.dateTime timeIntervalSinceReferenceDate]);
    for (i = 0; i < [self.points count]; i++) {
        if (i > 0) {
            [coordValues appendString:@", "];
        }
        point = [[self.points objectAtIndex:i] CGPointValue];
        [coordValues appendString:@"{\"x\":"];
        [coordValues appendString:[NSString stringWithFormat:@"%f, ", point.x]];
        [coordValues appendString:@"\"y\":"];
        [coordValues appendString:[NSString stringWithFormat:@"%f", point.y]];
        [coordValues appendString:@"}"];
    }
    [jsonString appendString:@"{\"timestamp\": "];
    //[jsonString appendString:[NSString stringWithFormat:@"%f", [dateTime timeIntervalSinceReferenceDate]]];
    [jsonString appendFormat:@"%f", [self.dateTime timeIntervalSinceReferenceDate]];
    [jsonString appendString:@", \"sessionID\": "];
    [jsonString appendFormat:@"\"%@\"", self.sessionID];
    [jsonString appendString:@", \"data\": ["];
    [jsonString appendString:coordValues];
    [jsonString appendString:@"]}"];
    NSLog(@"json string:\n%@", jsonString);
    
	NSLog(@"sending %lu points to the server\n", (unsigned long)[self.points count]);
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFJSONResponseSerializer serializer];
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:jsonString forKey:@"data"];
	[manager POST:@"http://localhost:8888/draw/postData" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"%@", responseObject);
		/* clear points here, get the points from server to reconstruct the whole drawing */
		[self.points removeAllObjects];
		[self.view drawRect:[self.view bounds]];
	} failure:nil];
	
}

- (IBAction)getPoints:(id)sender
{
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFJSONResponseSerializer serializer];
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	[parameters setObject:self.sessionID forKey:@"sessionID"];
	[parameters setObject:[NSNumber numberWithInteger:[self.dateTime timeIntervalSinceReferenceDate]] forKey:@"timestamp"];
	[manager GET:@"http://localhost:8888/draw/getAllData" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		int i, j;
		CGPoint point;
		NSValue *pointValue;
		// Use when fetching text data
		NSLog(@"received http response: %@", responseObject);
		NSDictionary *dict = (NSDictionary *)responseObject;
		if ([dict valueForKey:@"sessionID"] != nil) {
			self.sessionID = [dict valueForKey:@"sessionID"] ;
		}
		NSLog(@"sessionID = %@", self.sessionID);
		if ([dict valueForKey:@"data"] != nil) {
			NSArray *dataArray = (NSArray *)[dict valueForKey:@"data"];
			for (j = 0; j < [dataArray count]; j++) {
				NSDictionary *element = (NSDictionary *)[dataArray objectAtIndex:j];
				NSArray *coordArray = [element valueForKey:@"data"];
				NSLog(@"there are %lu element in the array\n", (unsigned long)[coordArray count]);
				for (i = 0; i < [coordArray count]; i++) {
					NSDictionary *coordinatePt = (NSDictionary *)[coordArray objectAtIndex:i];
					point.x = [[coordinatePt valueForKey:@"x"] doubleValue];
					point.y = [[coordinatePt valueForKey:@"y"] doubleValue];
					pointValue = [NSValue valueWithCGPoint:point];
					[self.points addObject:pointValue];
					NSLog(@"%f, %f", [pointValue CGPointValue].x, [pointValue CGPointValue].y);
				}
			}
			[self.view drawRect:[self.view bounds]];
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"http request return error, error description: %@", [error localizedDescription]);
	}];
}

-(void)disMissSaveDialog
{
    if (self.popOver != nil) {
        [self.popOver dismissPopoverAnimated:NO];
    }
}

-(void)disMissImportDialog
{
    if (self.popOver != nil) {
        [self.popOver dismissPopoverAnimated:NO];
    }
}

-(IBAction)saveDrawing:(id)sender
{
    CGFloat height;
    UIButton *saveButton = (UIButton *)sender;
    Draw2View * myView = (Draw2View *)self.view;
    Draw2SaveController *saveController = [[Draw2SaveController alloc] initWithStyle:UITableViewStylePlain];
    saveController.delegate = self;
    [saveController sendPictureToView:myView.image];
    self.popOver = [[UIPopoverController alloc] initWithContentViewController:saveController];
    height = 40 * 2; // 2 is the number of rows we have for this pop up
    self.popOver.popoverContentSize = CGSizeMake(240, height);
    /*
    [popOver presentPopoverFromRect:CGRectMake(saveButton.frame.origin.x + saveButton.frame.size.width, (saveButton.frame.origin.y*2 + saveButton.frame.size.height)/2, 1, 1) 
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionLeft 
                           animated:YES];
     */
    [self.popOver presentPopoverFromRect:saveButton.frame
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionAny 
                           animated:YES];
}

- (IBAction)deleteDrawing:(id)sender
{
    Draw2View *imgView;
    
    /* clean the canvas, remove all array points and bg image */
    [self.points removeAllObjects];
    [self.lastPointFromUser removeAllObjects];
    [self.markerArray removeAllObjects];
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
    self.popOver = [[UIPopoverController alloc] initWithContentViewController:importController];
    height = 40*2;
    self.popOver.popoverContentSize = CGSizeMake(240, height);
    [self.popOver presentPopoverFromRect:importButton.frame
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
    NSLog(@"image orientation displayed on screen is %ld", [imgView.image imageOrientation]);
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    Draw2View * imgView;
    UIImage *photo = [info valueForKey:UIImagePickerControllerOriginalImage];
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
}

- (IBAction) setColor:(id)sender
{
    NSInteger number;
    ui_color_t old_color;
    UIButton *button = (UIButton *)sender;
    
    if (!self.markerArray) {
        self.markerArray = [[NSMutableArray alloc] init];
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
    return self.connected;
}

@end
