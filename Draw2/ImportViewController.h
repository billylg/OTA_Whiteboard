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
}

@property (nonatomic, strong) NSArray *cellTitle;
@property (nonatomic, strong) Draw2ViewController *parent;
@property (copy) id<ImportControllerDelegate> delegate;
@property (nonatomic, strong) UIPopoverController *popOverController;

@end
