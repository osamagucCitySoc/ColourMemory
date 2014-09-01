//
//  HighScoreTableViewController.m
//  ColourMemory
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import "HighScoreTableViewController.h"
#import "DatabaseController.h"
#import "CONSTANTS.h"
#import "OLGhostAlertView.h"

@interface HighScoreTableViewController ()

@end

@implementation HighScoreTableViewController
{
    NSMutableArray* dataSource; // to hold the top 10 scores.
    DatabaseController* db; // to be used in db interactions
    UIRefreshControl* refreshControl; // to be used if user wants to refresh the global rankings. (will require internet or results will remain the same)
}

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
    db = [[DatabaseController alloc]init];
    dataSource = [db loadTopTenScores];
    [self.tableView reloadData];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotUpdate:)
                                                 name:@FINISHED_UPDATING_NOTIFICATION_NAME
                                               object:nil];
    
    refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(tryToSyncData) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    [refreshControl beginRefreshing];
    [self tryToSyncData];
}

-(void)tryToSyncData
{
    [db syncLocalWithOnlineDB];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait|UIInterfaceOrientationLandscapeLeft|UIInterfaceOrientationLandscapeRight|UIInterfaceOrientationMaskAllButUpsideDown;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationPortrait|UIInterfaceOrientationLandscapeLeft|UIInterfaceOrientationLandscapeRight|UIInterfaceOrientationMaskAllButUpsideDown;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)gotUpdate:(id)sender
{
    dataSource = [db loadTopTenScores];
    [refreshControl endRefreshing];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [dataSource count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* identifier = @"scoreCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if(!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
//    @"SELECT ID,USER,SCORE FROM SCORES ORDER BY SCORE DESC LIMIT 10;";

    
    NSDictionary* scoreEntry = [dataSource objectAtIndex:indexPath.row];
    
    [[cell textLabel]setTextColor:[UIColor whiteColor]];
    [[cell detailTextLabel]setTextColor:[UIColor yellowColor]];
    
    [[cell textLabel]setText:[NSString stringWithFormat:@"%@ : %i - %@ : %i",@"Score",[[scoreEntry objectForKey:@"SCORE"] intValue],@"Globally Ranked",[[scoreEntry objectForKey:@"GLOBALRANK"] intValue]]];
    
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[[scoreEntry objectForKey:@"OCCURED"] floatValue]];
    
    [[cell detailTextLabel]setText:[date description]];
    
    
    return cell;
}


- (IBAction)backPressed:(id)sender {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if(orientation != UIInterfaceOrientationPortrait)
    {
        OLGhostAlertView* alert = [[OLGhostAlertView alloc]initWithTitle:@"Sorry" message:@"Please get back to portrait mode" timeout:3 dismissible:YES];
        [alert show];
    }else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
@end
