//
//  Draw2View.h
//  Draw2
//
//  Created by Billy Liang on 8/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Draw2ViewController;

@interface Draw2View : UIImageView {
    CGPoint lastPoint;
}

@property (nonatomic, retain) IBOutlet Draw2ViewController *viewController;

- (void)updateView:(NSMutableArray *)arrayPoints withColor:(NSString *)colorStr;

@end
