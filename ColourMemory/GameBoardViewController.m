//
//  GameBoardViewController.m
//  ColourMemory
//
//  Created by OsamaMac on 9/1/14.
//  Copyright (c) 2014 Osama Rabie. All rights reserved.
//

#import "GameBoardViewController.h"

@interface GameBoardViewController ()

@end

@implementation GameBoardViewController
{
    /**
     Those arrays to be used in randomly filling the board.
     The algorthim written by me is a modified concept of the "index sort" algorithm.
     **/
    NSMutableArray* countArray;//ith entry tells how many times allAvailbleDataArray(i) had been put on the board (0,1,2).
    NSMutableArray* randomFilledArray;//ith entry is a random value from 1-8
    NSMutableArray* allAvailbleDataArray;//ith entry is availbe entry from 1-8 that yet can be added to the board.
    
    /**
     Index pathes are to hold the values of the cards the user flipped if any.
     **/
    NSIndexPath* firstOpenedCard;
    NSIndexPath* secondOpenedCard;
    
    /**
     Those are to hold and show the score.
     **/
    UILabel * scoreLabel;
    int score;
}

#define DEGREES_TO_RADIANS(angle) (angle / 180.0 * M_PI)


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
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
        
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind: UICollectionElementKindSectionHeader withReuseIdentifier:@"headerSection"];

    
    // initializing the board
    [self randomizeTheBoard];
    
}

/**
 This method is for randomizing the board at the beginning of the game.
 I have implemented a quick tricky algorithm based on the "Index Sort".
 **/

-(void)randomizeTheBoard
{
    score = 0;
    
    firstOpenedCard = nil;
    secondOpenedCard = nil;
    
    countArray = [[NSMutableArray alloc]init];
    randomFilledArray = [[NSMutableArray alloc]init];
    allAvailbleDataArray = [[NSMutableArray alloc]init];
    
    for(int i = 1 ; i < 9 ; i++)
    {
        [allAvailbleDataArray addObject:[NSString stringWithFormat:@"%i",i]];
        [countArray addObject:@"0"];
    }
    
    
    while(randomFilledArray.count<16)
    {
        int randNum = arc4random() % (countArray.count);
        [randomFilledArray addObject:[allAvailbleDataArray objectAtIndex:randNum]];
        int increaseCount = [[countArray objectAtIndex:randNum] intValue]+1;
        if(increaseCount>=2)
        {
            [allAvailbleDataArray removeObjectAtIndex:randNum];
            [countArray removeObjectAtIndex:randNum];
        }else
        {
            [countArray replaceObjectAtIndex:randNum withObject:[NSString stringWithFormat:@"%i",increaseCount]];
        }
    }
    [self.collectionView reloadData];
}
/**
 This method is for updating the score label whenver needed.
 **/
-(void)updateScoreLabel
{
    [scoreLabel setText:[NSString stringWithFormat:@"%@ : %i",@"Your Score Is",score]];
    [scoreLabel setNeedsDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UICollectionView Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return randomFilledArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellID = @"cardCell";
    
    UICollectionViewCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    
    [(UIImageView*)[cell viewWithTag:1] setAlpha:0.0f];
    
    
    //fade in
    [UIView animateWithDuration:0.5f delay:((CGFloat)indexPath.row/10.0f) options:UIViewAnimationOptionCurveEaseIn animations:^{
        [(UIImageView*)[cell viewWithTag:1] setAlpha:1.0f];
    } completion:^(BOOL finished) {
    }];
    
    cell.layer.shadowColor = [UIColor whiteColor].CGColor;
    cell.layer.shadowOffset = CGSizeMake(0, 0);
    cell.layer.shadowOpacity = 1;
    cell.layer.shadowRadius = 5.0;
    cell.layer.cornerRadius = 20.0f;
    
    return cell;
    
}

-(void)startAnimation:(UICollectionViewCell*)lockView
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1f];
    [UIView setAnimationRepeatAutoreverses:YES];
    [UIView setAnimationRepeatCount:10000];
    CGAffineTransform transform =
    CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(10));
    lockView.transform = transform;
    [UIView commitAnimations];
    
}

-(void)stopAnimation:(UICollectionViewCell*)lockView
{
    [lockView.layer removeAllAnimations];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.1f];
    [UIView setAnimationRepeatCount:1];
    CGAffineTransform transform =
    CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(0));
    lockView.transform = transform;
    [UIView commitAnimations];

}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize retval =  CGSizeMake(70, 85);
    return retval;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 0, 10, 0);
}

/**
 This is a delegate method that is being called whenever a user clicks on an item on the board. Possible paths are:
 1- User clicks to flip the first card. So this card is flipped and saved.
 2- User clicks to un-flip an oppened card. So this card is un-flipped and undo saved.
 3- User clicks to flip the second card. So this card is flipped and saved and compared agains the first one. If match increase coins and hide them from the board, if not decrease coins and un-flip them all.
 **/

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:1];
    
    if(firstOpenedCard != nil)
    {
        if(firstOpenedCard == indexPath) // close opened card
        {
            firstOpenedCard = nil;
            [UIView transitionWithView:imageView
                              duration:0.4
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                imageView.image = [UIImage imageNamed:@"card_bg.png"];
                            } completion:^(BOOL finished) {
                                [self stopAnimation:cell];
                            }];

            return;
        }
    }
    
    
    if(secondOpenedCard != nil)
    {
        if(secondOpenedCard == indexPath) // close opened card
        {
            secondOpenedCard = nil;
            [UIView transitionWithView:imageView
                              duration:0.4
                               options:UIViewAnimationOptionTransitionFlipFromRight
                            animations:^{
                                imageView.image = [UIImage imageNamed:@"card_bg.png"];
                            } completion:^(BOOL finished) {
                                [self stopAnimation:cell];
                            }];
            
            return;
        }
    }
    
    if(firstOpenedCard == nil)
    {//first to open a card
        firstOpenedCard = indexPath;
        [UIView transitionWithView:imageView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        animations:^{
                            imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%@%@",@"colour",[randomFilledArray objectAtIndex:indexPath.row],@".png"]];
                        } completion:^(BOOL finished) {
                            [self startAnimation:cell];
                        }];
        return;
    }
    
    if(secondOpenedCard == nil)
    {//second to open a card
        [self.collectionView setUserInteractionEnabled:NO];
        secondOpenedCard = indexPath;
        [UIView transitionWithView:imageView
                          duration:0.4
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        animations:^{
                            imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@%@%@",@"colour",[randomFilledArray objectAtIndex:indexPath.row],@".png"]];
                        } completion:^(BOOL finished) {
                            [self startAnimation:cell];
                            // need to check for a match and act accordingly
                            if([[randomFilledArray objectAtIndex:firstOpenedCard.row]isEqualToString:[randomFilledArray objectAtIndex:secondOpenedCard.row]])
                            {
                                score+=2;
                                [self updateScoreLabel];
                                [self performSelector:@selector(makeTheTwoMatchedUnClickable) withObject:nil afterDelay:1];
                            }else
                            {
                                score--;
                                [self updateScoreLabel];
                                [self performSelector:@selector(unFlipTheNonMatched) withObject:nil afterDelay:1];
                            }
                        }];
        return;
    }
}


-(void)makeTheTwoMatchedUnClickable
{
    UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:firstOpenedCard];
    [self stopAnimation:cell];
    [cell setUserInteractionEnabled:NO];
    UICollectionViewCell* cell2 = [self.collectionView cellForItemAtIndexPath:secondOpenedCard];
    [self stopAnimation:cell2];
    [cell2 setUserInteractionEnabled:NO];
    
    firstOpenedCard = nil;
    secondOpenedCard = nil;
    [self.collectionView setUserInteractionEnabled:YES];
}

-(void)unFlipTheNonMatched
{
    UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:firstOpenedCard];
    UIImageView* imageView = (UIImageView*)[cell viewWithTag:1];
    [UIView transitionWithView:imageView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        imageView.image = [UIImage imageNamed:@"card_bg.png"];
                    } completion:^(BOOL finished) {
                        [self stopAnimation:cell];
                    }];
    
    UICollectionViewCell* cell2 = [self.collectionView cellForItemAtIndexPath:secondOpenedCard];
    UIImageView* imageView2 = (UIImageView*)[cell2 viewWithTag:1];
    [UIView transitionWithView:imageView2
                      duration:0.4
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        imageView2.image = [UIImage imageNamed:@"card_bg.png"];
                    } completion:^(BOOL finished) {
                        [self stopAnimation:cell2];
                    }];

    
    firstOpenedCard = nil;
    secondOpenedCard = nil;
    [self.collectionView setUserInteractionEnabled:YES];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerSection" forIndexPath:indexPath];
        
        if (reusableview==nil) {
            reusableview=[[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, 320, 24)];
        }
        [reusableview setBackgroundColor:[UIColor clearColor]];
        [scoreLabel removeFromSuperview];
        scoreLabel=[[UILabel alloc] initWithFrame:CGRectMake(10, 5, 300, 15)];
        scoreLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f];
        scoreLabel.textAlignment = NSTextAlignmentCenter;
        [scoreLabel setBackgroundColor:[UIColor clearColor]];
        [scoreLabel setTextColor:[UIColor whiteColor]];
        [self updateScoreLabel];
        [reusableview addSubview:scoreLabel];
        return reusableview;
    }
    return nil;
}


@end
