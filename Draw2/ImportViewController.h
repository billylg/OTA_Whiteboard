//
//  ImportViewController.h
//  Draw2
//
//  Created by Billy Liang on 11/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Draw2ViewController;

@protocol ImportControllerDelegate <NSObject>

-(void) disMissImportDialog;

@end

@interface ImportViewController : UITableViewController {
    NSArray *cellTitle;
    Draw2ViewController *parent;
    id<ImportControllerDelegate> delegate;
    UIPopoverController *popOverController;
}

@property (nonatomic, retain) NSArray *cellTitle;
@property (nonatomic, retain) Draw2ViewController *parent;
@property (assign) id<ImportControllerDelegate> delegate;
@property (nonatomic, retain) UIPopoverController *popOverController;

@end
