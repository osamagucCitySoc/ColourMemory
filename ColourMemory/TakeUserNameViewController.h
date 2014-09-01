//
//  TakeUserNameViewController.h
//  ColourMemory
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TakeUserNameViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *takeUserNameTextField;
- (IBAction)submitPressed:(id)sender;

@end
