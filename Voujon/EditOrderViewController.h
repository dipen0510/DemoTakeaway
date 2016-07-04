//
//  EditOrderViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 22/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class AppDelegate;
@interface EditOrderViewController : UIViewController<UITableViewDataSource,UITableViewDelegate, UIAlertViewDelegate> {
    
    AppDelegate *delegate;
    
    NSMutableArray* itemArr;
    NSMutableArray* descriptionArr;
    
    
    //Ashwani :: Add discount functionality here
    NSString *MinimumRateForDiscount, *DiscountPercentage;
    NSString *MoreAmountReqdForDiscount;
    
}

@property (weak, nonatomic) IBOutlet UITableView *orderTblView;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceValLbl;

@property (weak, nonatomic) IBOutlet UILabel *SubTotalPriceValLbl;
@property (weak, nonatomic) IBOutlet UILabel *DiscountValLbl;

- (IBAction)addItemsButtonTapped:(id)sender;
- (IBAction)nextButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *DiscountofferInfoLabel;

@end
