//
//  DatabaseController.h
//  ColourMemory
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DatabaseController : NSObject


/**
 This method to be called by the controller when he wants to make sure that the database with along the columns are stored locally.
 **/
-(void)createDatabaseIfNotExists;

@end
