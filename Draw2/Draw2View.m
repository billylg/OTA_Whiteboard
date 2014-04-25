//
//  Draw2View.m
//  Draw2
//
//  Created by Billy Liang on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Draw2View.h"
#import "Draw2ViewController.h"


@implementation Draw2View

@synthesize viewController;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        super.userInteractionEnabled = NO;
        NSLog(@"not able to interact with the view");
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
     int i = 0;
     CGPoint point;
     // Drawing code
    self.image = nil;
    
     UIGraphicsBeginImageContext(self.frame.size);
     [self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
     CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
     CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5.0);
     CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
     
     while(i < [viewController.points count]) {
         CGContextBeginPath(UIGraphicsGetCurrentContext());
         point = [[viewController.points objectAtIndex:i] CGPointValue];
         CGContextMoveToPoint(UIGraphicsGetCurrentContext(), point.x, point.y);
         i++;
         for (; i < [viewController.points count]; i++) {
             point = [[viewController.points objectAtIndex:i] CGPointValue];
             if (point.x == -1 && point.y == -1) {
                 i++;
                 break;
             }
             CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), point.x, point.y);
         }
         CGContextStrokePath(UIGraphicsGetCurrentContext());
         self.image = UIGraphicsGetImageFromCurrentImageContext();
     }
     UIGraphicsEndImageContext();
}
*/

/* TODO: directly accessing the viewController in view is not a good
 *       design, should use a delegate here if possible, view will 
 *       get the data through the delegate's method, which is 
 *       implemented by the view controller. 
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self];
    NSValue *point;
    
    if ([viewController getMode] == NONE_ACTIVE) {
        return;
    }
#if 0    
    if ([touch tapCount] == 2) {
        self.image = nil;
        return;
    } else if ([touch tapCount] == 3) {
        NSLog(@"there are %d points in the array", [viewController.points count]);
        //[self drawRect:[self bounds]];
        [viewController refreshView];
    } else {
#endif
        //[points addObject:[NSValue valueWithCGPoint:lastPoint]];
        point = [NSValue valueWithCGPoint:lastPoint];
        [viewController.points addObject:point];
    //}
    
    NSLog(@"touching the screen");
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    static int moves = 0;
    //CGContextRef c = UIGraphicsGetCurrentContext();
    NSValue *point;
    
    UITouch *touch = [touches anyObject];   
    CGPoint currentPoint = [touch locationInView:self];
    //currentPoint.y -= 20;
    
    if ([viewController getMode] == NONE_ACTIVE) {
        return;
    }
    
    point = [NSValue valueWithCGPoint:currentPoint];
    [viewController.points addObject:point];
    moves++;
    if (moves % 15 == 0) {
        if ([viewController isConnected]) {
            [viewController sendCoordinates:nil];
        }
    }
    
    UIGraphicsBeginImageContext(self.bounds.size);
    //UIGraphicsBeginImageContext(self.frame.size);
    //[self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self.image drawInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5.0);
    if ([viewController getMode] == DRAW) {
        if ([viewController getColor] == BLACK) {
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 1.0);
        } else if ([viewController getColor] == RED) {
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
        } else if ([viewController getColor] == GREEN) {
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 1.0, 0.0, 1.0);
        } else if ([viewController getColor] == BLUE) {
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 1.0, 1.0);
        }
    } else if ([viewController getMode] == ERASE) {
        /* set the RGB value to 1.0 - white */
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 1.0, 1.0, 1.0);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 10.0);
    }
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
     
    lastPoint = currentPoint;
     
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint endPoint;
    NSValue *point;
    
    if ([viewController getMode] == NONE_ACTIVE) {
        return;
    }
    
    endPoint.x = -1;
    endPoint.y = -1;
    point = [NSValue valueWithCGPoint:endPoint];
    [viewController.points addObject:point];
    NSLog(@"there are total %d points in the array", [viewController.points count]);
}

- (void)updateView:(NSMutableArray *)arrayPoints withColor:(NSString *)colorStr
{
    int i = 0;
    CGPoint point;
    
    //UIGraphicsBeginImageContext(self.frame.size);
    UIGraphicsBeginImageContext(self.bounds.size);
    //[self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self.image drawInRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    //[self.image drawInRect:CGRectMake(0, 0, self.frame.size.height, self.frame.size.width)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5.0);
    if ([colorStr isEqualToString:@"BLACK"]) {
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 1.0);
    } else if ([colorStr isEqualToString:@"RED"]) {
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
    } else if ([colorStr isEqualToString:@"GREEN"]) {
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 1.0, 0.0, 1.0);
    } else if ([colorStr isEqualToString:@"BLUE"]) {
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 1.0, 1.0);
    }
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    while(i < [arrayPoints count]) {
        point = [[arrayPoints objectAtIndex:i] CGPointValue];
        if (point.x == -1 && point.y == -1) {
            i++;
            continue;
        }
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), point.x, point.y);
        i++;
        for (; i < [arrayPoints count]; i++) {
            point = [[arrayPoints objectAtIndex:i] CGPointValue];
            if (point.x == -1 && point.y == -1) {
                i++;
                break;
            }
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), point.x, point.y);
        }
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        self.image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
}

- (void)dealloc
{
    [super dealloc];
}

@end
