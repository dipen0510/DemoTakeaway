//
//  OrderDetailsViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZFormSheetController.h"
#import "MZFormSheetSegue.h"

@interface OrderDetailsViewController : UIViewController<UITextFieldDelegate,UIPickerViewDataSource,UIPickerViewDelegate,UIScrollViewDelegate, UIAlertViewDelegate, UITextViewDelegate> {
    
    float scrollViewHeight;
    int orderType;
    int paymentType;
    BOOL isLoadedForFirstTime;
    
    NSMutableArray* collectionReqArr;
    NSMutableArray* deliveryReqArr;
    
    NSString* selectedPickerContent;
    UIPickerView* picker;
    
    NSString* selectedPickerContent1;
    UIPickerView* picker1;
    
    //Ashwani:: Sep 14 2015
    NSString *scheduleDateTime;
    
    
    int collectionInterval;
    int deliverInterval;
    
    int isDeliveryPostalCodeInvalid;
    
    BOOL showKeyboardAnimation;
    CGPoint viewCenter;
    
    NSString* orderTotal;
    
    int isSecondTime;
    //
    
}

@property (weak, nonatomic) IBOutlet UITextView *instructionsTextView;
@property (weak, nonatomic) IBOutlet UIButton *deliveryCheckbox;
@property (weak, nonatomic) IBOutlet UIButton *collectionCheckbox;
@property (weak, nonatomic) IBOutlet UILabel *choosePaymentLbl;
@property (weak, nonatomic) IBOutlet UILabel *cashLbl;
@property (weak, nonatomic) IBOutlet UILabel *paypalLbl;
@property (weak, nonatomic) IBOutlet UILabel *stripeLbl;
@property (weak, nonatomic) IBOutlet UIButton *cashCheckbox;
@property (weak, nonatomic) IBOutlet UIButton *paypalCheckbox;
@property (weak, nonatomic) IBOutlet UIButton *stripeCheckbox;
@property (weak, nonatomic) IBOutlet UILabel *deliveryPostCodeLbl;
@property (weak, nonatomic) IBOutlet UITextField *deliveryPostcodeTxtField;
@property (weak, nonatomic) IBOutlet UILabel *adress1Lbl;
@property (weak, nonatomic) IBOutlet UITextField *address1TxtField;
@property (weak, nonatomic) IBOutlet UILabel *address2Lbl;
@property (weak, nonatomic) IBOutlet UITextField *address2TxtField;
@property (weak, nonatomic) IBOutlet UILabel *townLbl;
@property (weak, nonatomic) IBOutlet UITextField *townTxtField;
@property (weak, nonatomic) IBOutlet UILabel *requestTimeLbl;
@property (weak, nonatomic) IBOutlet UITextField *requestTimeTxtField;
@property (weak, nonatomic) IBOutlet UIScrollView *contentScrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *requestTimeLblTopConstraint;

@property (weak, nonatomic) IBOutlet UILabel *invalidPostcodeLbl;

//Ashwani :: This will be use to show message for online payment charge
@property (weak, nonatomic) IBOutlet UILabel *lblChoosePaymentMethod;

@property (weak, nonatomic) IBOutlet UILabel *deliveryTimeLbl;
@property (weak, nonatomic) IBOutlet UILabel *collectionTimeLbl;

- (IBAction)deliveryCheckboxTapped:(id)sender;
- (IBAction)collectionCheckboxTapped:(id)sender;
- (IBAction)cashCheckboxTapped:(id)sender;
- (IBAction)paypalCheckboxTapped:(id)sender;
- (IBAction)backButtonTapped:(id)sender;
- (IBAction)nextButtonTapped:(id)sender;

- (IBAction)stripeCheckboxTapped:(id)sender;


@end
