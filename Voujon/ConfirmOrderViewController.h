//
//  ConfirmOrderViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConfirmOrderViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,PayPalPaymentDelegate, DataSyncManagerDelegate> {
    
    NSMutableArray* itemArr;
    NSString* resultText;
    BOOL isOrderConfirmed;
    
    //Ashwani
    NSString  *PayPalData, *PayPalPayerID, *PaypalPaymentId, *PayPalSaleID, *ePayCharge, *orderDateTime, *clientIP, *scheduleDateTime, *orderTotal;
    
    //Ashwani :: After discount implementation, use these values for total
    NSString *subTotal, *discountRate, *grandTotal;
}

@property (weak, nonatomic) IBOutlet UITableView *itemTblView;
@property (weak, nonatomic) IBOutlet UILabel *totalPriceLbl;
@property (weak, nonatomic) IBOutlet UILabel *instructionLbl;
@property (weak, nonatomic) IBOutlet UILabel *orderTypeHeadingLbl;
@property (weak, nonatomic) IBOutlet UILabel *orderTypeSubHeadingLbl;
@property (weak, nonatomic) IBOutlet UILabel *orderTypeValueLbl;

- (IBAction)backButtonTapped:(id)sender;
- (IBAction)nextButtonTapped:(id)sender;


@end
