//
//  TakeUserNameViewController.m
//  ColourMemory
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import "TakeUserNameViewController.h"
#import "CONSTANTS.h"
#import "OLGhostAlertView.h"

@interface TakeUserNameViewController ()

@end

@implementation TakeUserNameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.takeUserNameTextField becomeFirstResponder];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)submitPressed:(id)sender {
    [self.takeUserNameTextField resignFirstResponder];
    if(self.takeUserNameTextField.text.length <= 0)// empty then feedback
    {
        OLGhostAlertView* alert = [[OLGhostAlertView alloc]initWithTitle:@"Sorry" message:@"Username cannot be empty." timeout:3 dismissible:YES];
        [alert show];
    }else// not empty, then store it and store the salt (default timestamp) then notify the board to store the new score and to rebuild itself.
    {
        [[NSUserDefaults standardUserDefaults]setObject:self.takeUserNameTextField.text forKey:@STORREDUSERNAME];
        [[NSUserDefaults standardUserDefaults]setObject:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] forKey:@STORREDSERVERSALT];
        [[NSUserDefaults standardUserDefaults]synchronize];
    [self dismissViewControllerAnimated:YES completion:^(void){
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@FINISHED_USERNAME_NOTIFICATION_NAME
         object:self];
    }];
    }
}
@end
