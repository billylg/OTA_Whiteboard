//
//  Draw2SaveController.m
//  Draw2
//
//  Created by Billy Liang on 10/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Draw2SaveController.h"
#import <MessageUI/MessageUI.h>


@implementation Draw2SaveController

@synthesize cellTitle;
@synthesize mainImage;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.cellTitle = [NSArray arrayWithObjects:@"Email", @"Photo Album", nil];
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [cellTitle count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = [cellTitle objectAtIndex:indexPath.row];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/* obtain the screen image of the calling controller */ 
-(void) sendPictureToView:(UIImage *)image
{
    self.mainImage = image;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    if (indexPath.row == 0) {
        NSLog(@"email selected");
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        /* email */
        // Set the subject of email
        [picker setSubject:@"Picture from my iPad!"];
        // Add email addresses
        // Notice three sections: "to" "cc" and "bcc"	
        [picker setToRecipients:[NSArray arrayWithObjects:@"billylg@gmail.com", nil]];
        [picker setCcRecipients:[NSArray arrayWithObject:@"wchiu10193@gmail.com"]];	
        // Fill out the email body text
        NSString *emailBody = @"I just took this picture, check it out.";
        // This is not an HTML formatted email
        [picker setMessageBody:emailBody isHTML:NO];
        
        // Create NSData object as JPG image data from camera image
        NSData *data = UIImageJPEGRepresentation(self.mainImage, 1.0);
        
        // Attach image data to the email
        // 'CameraImage.png' is the file name that will be attached to the email
        [picker addAttachmentData:data mimeType:@"image/png" fileName:@"CameraImage"];
        
        // Show email view	
        [self presentModalViewController:picker animated:YES];
        
        // Release picker
        [self.delegate disMissSaveDialog];
        
    } else if (indexPath.row == 1) {
        /* save to photo album */
        NSLog(@"photo album selected");
        UIImageWriteToSavedPhotosAlbum(self.mainImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        [self.delegate disMissSaveDialog];
    }
}

-(void) image:(UIImage *)image didFinishSavingWithError:(NSError *)error 
        contextInfo:(void *)contextInfo {
    UIAlertView *alert;
    
    if (error != nil) {
        // show error message
        alert = [[UIAlertView alloc] initWithTitle:nil message:@"Fail to save drawing to album" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    } else {
        // show success message
        alert = [[UIAlertView alloc] initWithTitle:nil message:@"Drawing successfully saved to album" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    // Called once the email is sent
    // Remove the email view controller	
    [self dismissModalViewControllerAnimated:YES];
}

@end
