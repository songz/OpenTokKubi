//
//  RoomViewController.m
//  KubiApp
//
//  Created by Song Zheng on 7/2/13.
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//

#import "RoomViewController.h"
#import "ServiceViewController.h"

@interface RoomViewController ()

@end

@implementation RoomViewController{
    UITableView *myTableView;
    NSDictionary* allRooms;
}

@synthesize tableData;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.rowHeight = 80;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Cancel"
                                              style:UIBarButtonItemStyleDone
                                              target:self
                                              action:@selector(cancel:)];
    self.navigationItem.title = @"Available Rooms";
    NSURL *url = [NSURL URLWithString:@"http://tnw.herokuapp.com/rooms.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    
    NSError* error;
    NSURLResponse *urlResponse = nil;
    NSData *response1 = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    allRooms = [NSJSONSerialization JSONObjectWithData:response1 options:kNilOptions error:&error];
//    NSLog(@"all rooms: %@",allRooms);
    
    tableData = [allRooms allKeys];
}

- (void) cancel:(id) sender
{
    [self dismissModalViewControllerAnimated:YES];
}


- (void) reload {
    [self.tableView reloadData];
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
    return [tableData count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell"];
    if(cell==nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyCell"];
    }
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.textLabel.font = [UIFont systemFontOfSize:25];
    return cell;
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
     */
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NSString* roomName = cell.textLabel.text;
        NSDictionary* roomDetails = [allRooms objectForKey:roomName];
    
//    NSLog(@"index path: %@", indexPath);
//    NSLog(@"room name: %@", roomName);
//    NSLog(@"room details: %@", roomDetails);
//    
//    NSLog(@" api key: %@", [roomDetails objectForKey:@"apiKey"]);
//    NSLog(@" session: %@", [roomDetails objectForKey:@"session"]);
//    NSLog(@" token: %@", [roomDetails objectForKey:@"token"]);
    [self.serviceViewController joinNewSession:[roomDetails objectForKey:@"apiKey"]
                                   withSession:[roomDetails objectForKey:@"session"]
                                  withRoomName: roomName
                                      andToken:[roomDetails objectForKey:@"token"]];
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void) connect:(id) sender {
    [self.serviceViewController connectToPeripheralAtIndex:[sender tag]];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation == UIInterfaceOrientationPortrait;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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



@end
