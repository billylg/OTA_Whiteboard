//
//  Draw2SaveController.h
//  Draw2
//
//  Created by Billy Liang on 10/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@protocol Draw2SaveControllerDelegate <NSObject>

-(void) disMissSaveDialog;

@end


@interface Draw2SaveController : UITableViewController <MFMailComposeViewControllerDelegate> {
}

@property (nonatomic, strong) NSArray *cellTitle;
@property (nonatomic, strong) UIImage *mainImage;
@property (nonatomic, weak) id<Draw2SaveControllerDelegate> delegate;

-(void) sendPictureToView:(UIImage *)image;

@end
