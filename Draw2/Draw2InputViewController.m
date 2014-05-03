//
//  Draw2InputViewController.m
//  Draw2
//
//  Created by Billy Liang on 9/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Draw2InputViewController.h"
#import "Draw2ViewController.h"


@implementation Draw2InputViewController

@synthesize ipTextField;
@synthesize sessionTextField;
@synthesize userTextField;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
	return YES;
}

- (IBAction) onDone:(id)sender
{
    Boolean isOk = TRUE;
    NSString *ip, *user, *session;
    UIButton *button = (UIButton *)sender;
    
    ip = ipTextField.text;
    session = sessionTextField.text;
    user = userTextField.text;
    
    if ([button.titleLabel.text isEqualToString:@"Cancel"]) {
        isOk = FALSE;
    }
    [self.delegate userInputFinish:ip withSessionID:session withUserName:user isConfirm:isOk];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.ipTextField) {
        [theTextField resignFirstResponder];
    } else if (theTextField == self.sessionTextField) {
        [theTextField resignFirstResponder];
    } else if (theTextField == self.userTextField) {
        [theTextField resignFirstResponder];
    }
    return YES;
}

@end
