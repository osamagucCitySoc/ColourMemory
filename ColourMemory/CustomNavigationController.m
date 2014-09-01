//
//  CustomNavigationController.m
//  FtcTask
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import "CustomNavigationController.h"

@interface CustomNavigationController ()

@end

@implementation CustomNavigationController


- (BOOL)shouldAutorotate {
    return [self.visibleViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [self.visibleViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.visibleViewController preferredInterfaceOrientationForPresentation];
}

@end
