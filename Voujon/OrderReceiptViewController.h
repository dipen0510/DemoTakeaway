//
//  OrderReceiptViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 04/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SharedContent.h"

@interface OrderReceiptViewController : UIViewController<UITableViewDataSource,UITableViewDelegate> {
    
    NSMutableArray* itemArr;
    
}
@property (weak, nonatomic) IBOutlet UILabel *orderPlacedAtValLbl;
@property (weak, nonatomic) IBOutlet UILabel *collectionRequestValLbl;
@property (weak, nonatomic) IBOutlet UILabel *specialInstructionsValLbl;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLbl;
@property (weak, nonatomic) IBOutlet UITableView *itemTBlView;
@property (weak, nonatomic) IBOutlet UILabel *collectionRequestLbl;
- (IBAction)HomeButtonTapped:(id)sender;

@end
