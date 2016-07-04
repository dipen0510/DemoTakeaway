//
//  ViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MODropAlertView.h"
#import "XMLDictionary.h"

@interface ViewController : UIViewController<UIActionSheetDelegate, MODropAlertViewDelegate, DataSyncManagerDelegate>
{
    NSMutableArray* deliveryTimingArr;
    NSMutableArray* collectionTimingArr;

}
- (IBAction)RefreshButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *RefreshButton;
- (IBAction)orderButtonTapped:(id)sender;
- (IBAction)findButtonTapped:(id)sender;
- (IBAction)infoButtonTapped:(id)sender;
- (IBAction)webLinkButtonTapped:(id)sender;

@end

