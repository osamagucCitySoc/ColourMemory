//
//  DatabaseController.m
//  ColourMemory
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import "DatabaseController.h"
#import <sqlite3.h>
#import "CONSTANTS.h"


@implementation DatabaseController
{
    NSString *databasePath; // to hold the path the local db will be stored in.
    sqlite3 *localScoresDB; // the real object to hold reference to the local database.
}

/**
 This method to be called by the controller when he wants to make sure that the database with along the columns are stored locally.
 **/

-(void)createDatabaseIfNotExists
{
    databasePath = [self configureDatabasePath];
    
    // check if it is not already there, then create the database with all its tables then store it
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    if ([filemgr fileExistsAtPath: databasePath ] == NO) // DB is not there, need to create one.
    {
        const char *dbpath = [databasePath UTF8String];
        
        if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
        {
            char *errMsg;
            // creating the all jobs table
            const char *sql_stmt =
            "CREATE TABLE IF NOT EXISTS SCORES (ID INTEGER PRIMARY KEY , USER TEXT, SCORE INTEGER, OCCURED INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,GLOBALRANK INTEGER DEFAULT -1)";
            
            if (sqlite3_exec(localScoresDB, sql_stmt, NULL, NULL, &errMsg) == SQLITE_OK)
            {
                NSLog(@"%@",@"Successfully to create SCORES table");
            }else
            {
                NSLog(@"%@",@"Failed to create SCORES table");
            }
        }
    }
}

/**
 This method is to be used to initialize the path the database will be stored into.
 **/
-(NSString*)configureDatabasePath
{
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(
                                                   NSDocumentDirectory, NSUserDomainMask, YES);
    
    docsDir = dirPaths[0];
    
    // Build the path to the database file
    return  [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: @DATABASENAME]];
}



/**
 This method to be called by the controller when he wants to insert new score record locally.
 **/
-(void)insertNewScoredRecord:(int)score
{
    databasePath = [self configureDatabasePath];
    sqlite3_stmt    *statement;
    const char *dbpath = [databasePath UTF8String];
    
    if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
    {
        NSString* storedUserName = [[NSUserDefaults standardUserDefaults]objectForKey:@STORREDUSERNAME];
        
        NSString *insertSQL = [NSString stringWithFormat:
                               @"INSERT INTO SCORES (USER, SCORE) VALUES (\"%@\", \"%i\")",
                               storedUserName,
                               score];
        
        const char *insert_stmt = [insertSQL UTF8String];
        const char *errMsg;
        sqlite3_prepare_v2(localScoresDB, insert_stmt,
                           -1, &statement, &errMsg);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"%@",@"SCORE ADDED");
        } else {
            NSLog(@"%@.",@"Failed to add SCORE");
        }
        sqlite3_finalize(statement);
        sqlite3_close(localScoresDB);
    }
}
@end
