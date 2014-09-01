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
#import "Reachability.h"

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
        
        [self syncLocalWithOnlineDB];
    }
}

/**
 This method to be called by the controller when he wants to sync between the local stored DB and between the online one. It checks first if the app is connected, then it loads data from the server async.
 The server replies in the data in JSON format.
 Then it notifies the contoller DB is synced.**/
-(void)syncLocalWithOnlineDB
{
    if(![self connected])
    {
        //We are not connected to the internet, then we cannot do anything and will have to keep only using what we have locally.
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@FINISHED_UPDATING_NOTIFICATION_NAME
         object:self];
    }else
    {
        //We are connected, first we will get all what we have in local storage (TOP 10 scores) as those only the ones that will be shown to the user. And then jsonify it to be able to post it on HTTP Post request to the server.
        NSMutableArray* topTenScores = [self loadTopTenScores];
        
        NSError* error;
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:topTenScores options:NSJSONWritingPrettyPrinted error:&error];
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        // Now prepare the HTTP Request to be sent to the server.
        responseData = [[NSMutableData alloc]init];
        
        NSString *post = @"locallyStoredValues=";
        post = [post stringByAppendingString:jsonString];
        
        NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
        
        NSURL *url = [NSURL URLWithString:@"http://osamalogician.com/accedo/syncEntries.php"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
        [request setHTTPMethod:@"POST"];
        
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:postData];
        
        updateConnection = [[NSURLConnection alloc]initWithRequest:request delegate:self    startImmediately:NO];
        
        [updateConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                    forMode:NSDefaultRunLoopMode];
        [updateConnection start];
    }
}

/**
 This method to be called by the controller when he wants to get the top 10 scores the user achieved till now.
 **/
-(NSMutableArray*)loadTopTenScores
{
    databasePath = [self configureDatabasePath];
    
    const char *dbpath = [databasePath UTF8String];
    sqlite3_stmt    *statement;
    
    NSMutableArray* topTenScores = [[NSMutableArray alloc]init];
    
    if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
    {
        NSString *querySQL =  @"SELECT ID,USER,SCORE FROM SCORES ORDER BY SCORE DESC LIMIT 10;";
        
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(localScoresDB,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                
                NSNumber* ID = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
                
                NSString *USER = [[NSString alloc]
                                  initWithUTF8String:
                                  (const char *) sqlite3_column_text(
                                                                     statement, 1)];
                USER = [USER stringByAppendingString:[[NSUserDefaults standardUserDefaults] objectForKey:@STORREDSERVERSALT]];
                
                NSNumber* SCORE =  [NSNumber numberWithInt:sqlite3_column_int(statement, 2)];
                
                NSDictionary* scoreEntry = [[NSDictionary alloc]initWithObjects:@[ID,USER,SCORE] forKeys:@[@"ID",@"USER",@"SCORE"]];
                
                [topTenScores addObject:scoreEntry];
                
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(localScoresDB);
    }
    return topTenScores;
}

-(BOOL)connected
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        return NO;
    } else {
        return YES;
    }
}


#pragma mark NSURLConnection Delegate
/**
 This method is from the delegate methods.
 We use it to append data returned by the server, in case server decides that data will not be sent as a whole and will be sent in parts instead.
 **/
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}

/**
 This method is from the delegate methods.
 It triggers that the connection finished and all data are now recieved.
 Then it parse the json returned by the server into an array. Then it updates the local storage and then notify the caller that update is finished.
 **/
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError* error;
    
    NSArray* dataFromServer =[NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:kNilOptions
                              error:&error];
    
    if(error)// then data may be corrupted, or anything else went wrong on server. So it is important to make sure that we a valid data before dealing with the local one and update it.
    {
        //Data is maleformed, so we end up here.
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@FINISHED_UPDATING_NOTIFICATION_NAME
         object:self];
    }else // Now, as we got the updated global rankings from the server. We will update them in the local db.
    {
        databasePath = [self configureDatabasePath];
        
        const char *dbpath = [databasePath UTF8String];
        sqlite3_stmt    *statement;
        
        if (sqlite3_open(dbpath, &localScoresDB) == SQLITE_OK)
        {
            
            for(NSDictionary* updateScoreEntry in dataFromServer)
            {
                NSNumber* ID = [updateScoreEntry objectForKey:@"ID"];
                
                NSNumber* globalRanking = [updateScoreEntry objectForKey:@"GLOBAL"];
                
                NSString *updateSQL = [NSString stringWithFormat:
                                       @"UPDATE SCORES SET GLOBALRANK=%i WHERE ID=%i",
                                       [globalRanking intValue],[ID intValue]];
                
                const char *update_stmt = [updateSQL UTF8String];
                const char *errMsg;
                sqlite3_prepare_v2(localScoresDB, update_stmt,
                                   -1, &statement, &errMsg);
                if (sqlite3_step(statement) == SQLITE_DONE)
                {
                    NSLog(@"%@ : %i",@"Updated",[ID intValue]);
                } else {
                    NSLog(@"%@ : %i",@"Failed To Update",[ID intValue]);
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(localScoresDB);
        }
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@FINISHED_UPDATING_NOTIFICATION_NAME
         object:self];
    }
}


@end
