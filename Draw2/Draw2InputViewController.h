//
//  Draw2InputViewController.h
//  Draw2
//
//  Created by Billy Liang on 9/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol Draw2InputViewDelegate <NSObject>

- (void) userInputFinish:(NSString *)server_ip 
         withSessionID:(NSString *)session_id 
         withUserName:(NSString *)user_name
         isConfirm:(Boolean)confirm;

@end

@interface Draw2InputViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UITextField *ipTextField;
    IBOutlet UITextField *sessionTextField;
    IBOutlet UITextField *userTextField;
    id <Draw2InputViewDelegate> delegate;
}

@property (nonatomic, retain) UITextField *ipTextField;
@property (nonatomic, retain) UITextField *sessionTextField;
@property (nonatomic, retain) UITextField *userTextField;
@property (assign) id <Draw2InputViewDelegate> delegate;

-(IBAction) onDone:(id)sender;

@end
