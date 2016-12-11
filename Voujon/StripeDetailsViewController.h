//
//  StripeDetailsViewController.h
//  W4FirePizza
//
//  Created by Dipen Sekhsaria on 05/05/16.
//  Copyright © 2016 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Stripe/Stripe.h>

@interface StripeDetailsViewController : UIViewController <STPPaymentCardTextFieldDelegate, DataSyncManagerDelegate> {
    NSString *MinimumRateForDiscount, *DiscountPercentage;
    NSString *MoreAmountReqdForDiscount;
}

@property(nonatomic) STPPaymentCardTextField *paymentTextField;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
- (IBAction)backButtonTapped:(id)sender;

@end
