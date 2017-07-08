//
//  OrderDetailsViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "OrderDetailsViewController.h"
#import "OrderDetailsAlertViewController.h"
#import "OrderViewController.h"
@interface OrderDetailsViewController ()

@end

@implementation OrderDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    orderTotal = @"";
    [self refreshFinalOrder];
    
//    UILabel *lblOnlinePaymentCharge = [[UILabel alloc] initWithFrame:CGRectMake(self.lblChoosePaymentMethod.frame.size.width+30, self.lblChoosePaymentMethod.frame.origin.y, [UIScreen mainScreen].bounds.size.height-(self.lblChoosePaymentMethod.frame.size.width+30), 21)];
//    lblOnlinePaymentCharge.textColor = [UIColor blackColor];
//    lblOnlinePaymentCharge.textAlignment = NSTextAlignmentRight;
//    lblOnlinePaymentCharge.text = @"Online Payment Charge $0.5.";
//    [self.view addSubview:lblOnlinePaymentCharge];
    
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard:)];
    [self.contentScrollView addGestureRecognizer:gestureRecognizer];
    
    [self.instructionsTextView setText:@""];
    [self.deliveryPostcodeTxtField setText:@""];
    [self.address1TxtField setText:@""];
    [self.address2TxtField setText:@""];
    [self.townTxtField setText:@""];
    
    self.deliveryPostcodeTxtField.tag = 101;
    self.deliveryPostcodeTxtField.delegate = self;
    
    self.address1TxtField.delegate = self;
    self.address2TxtField.delegate = self;
    self.townTxtField.delegate = self;
    
    collectionReqArr = [[NSMutableArray alloc] init];
    deliveryReqArr = [[NSMutableArray alloc] init];
    
    collectionInterval = [[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"CollectionTime"] intValue];
    deliverInterval = [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryTime"] intValue];
    
    self.deliveryTimeLbl.text = [NSString stringWithFormat:@"Delivery (Approx %d minutes)",deliverInterval];
    self.collectionTimeLbl.text = [NSString stringWithFormat:@"Collection (Approx %d minutes)",collectionInterval];
    
    showKeyboardAnimation = true;
    viewCenter = self.view.center;
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollTouch)];
    [recognizer setNumberOfTapsRequired:1];
    [recognizer setNumberOfTouchesRequired:1];
    [self.contentScrollView addGestureRecognizer:recognizer];
    self.contentScrollView.delegate = self;
    
    NSLog(@"Delivery thresh hold: %@", [[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"]);
    if([[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] == (id) [NSNull null])
    {
        self.deliveryCheckbox.hidden = TRUE;
    }
    
    
//    if ([[SharedContent sharedInstance] StripePublishKey]) {
        self.stripeLbl.hidden = NO;
        self.stripeCheckbox.hidden = NO;
//    }
//    else {
//        self.stripeLbl.hidden = YES;
//        self.stripeCheckbox.hidden = YES;
//    }

    if ([[SharedContent sharedInstance] PaypalSecretKey]) {
        self.paypalLbl.hidden = NO;
        self.paypalCheckbox.hidden = NO;
    }
    else {
        self.paypalLbl.hidden = YES;
        self.paypalCheckbox.hidden = YES;
    }
    
    _choosePaymentLbl.text = [NSString stringWithFormat:@"Choose Payment Method (Extra £%0.2f will be charged for online payment)",[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"ElectronicPaymentCharge"] floatValue]];
    
    [self setupPaymentMenthodUI];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupPaymentMenthodUI {
    
    NSString* paymentMethods = [[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"PaymentMethods"];
    
    self.paypalLbl.hidden = YES;
    self.paypalCheckbox.hidden = YES;
    self.cashLbl.hidden = YES;
    self.cashCheckbox.hidden = YES;
    self.stripeLbl.hidden = YES;
    self.stripeCheckbox.hidden = YES;
    
    
        if ([[paymentMethods lowercaseString] containsString:@"cash"]) {
            self.cashLbl.hidden = NO;
            self.cashCheckbox.hidden = NO;
        }
        if ([[paymentMethods lowercaseString] containsString:@"card"]) {
            self.stripeLbl.hidden = NO;
            self.stripeCheckbox.hidden = NO;
        }
        if ([[paymentMethods lowercaseString] containsString:@"paypal"]) {
            self.paypalLbl.hidden = NO;
            self.paypalCheckbox.hidden = NO;
        }
    
    
}

-(void)viewDidLayoutSubviews {
    
    if (!isLoadedForFirstTime) {
        self.contentScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 445);
        isLoadedForFirstTime = true;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) hideKeyBoard:(id) sender {
    
    [self.view endEditing:YES];
    
}

- (IBAction)deliveryCheckboxTapped:(id)sender {
    
    orderType = 1;
    if ([self validateMinimumOrderAmount_new])
    {
          if([self validateFreeDeliveryThreshold])
            {
                [self.deliveryCheckbox setImage:[UIImage imageNamed:@"Checked-checkbox.png"] forState:UIControlStateNormal];
                [self.collectionCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
                [self setupLayoutForOrderType];
            }
            else
            {
                NSString *amount = [NSString stringWithFormat:@"%.2f",[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]];
                double calculatedPrice = [[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] doubleValue];
                CGFloat moreAmount = [amount doubleValue] - calculatedPrice;
                //Ashwani :: Dec07 2015 Added amount for 2 digit only
                NSString *msg = [NSString stringWithFormat:@"Please add items worth £%@ or more into the cart for Free Delivery or your total will be automatically rounded off to £%@", [NSString stringWithFormat:@"%.02f", moreAmount],amount];
                //[@(moreAmount) stringValue]
                //[NSString stringWithFormat:@"%.02f", moreAmount]
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:msg delegate:self cancelButtonTitle:@"Round off" otherButtonTitles: @"Add Item", nil];
                [alert show];
                alert.tag = 100;
                return;
            }
        
    }
    else {
        
        NSString *amount = [NSString stringWithFormat:@"%.2f",[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"] floatValue]];
        NSString *msg = [@"Minimum amount for delivery is " stringByAppendingFormat:@"£%@", amount];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:msg delegate:self cancelButtonTitle:@"Add More Item" otherButtonTitles: @"Choose Collection",nil];
        [alert show];
        alert.tag = 200;
        return;
        
    }
    
    
//    if ([self validateMinimumOrderAmount])
//    {
//        [self performSegueWithIdentifier:@"orderTimeAlertSegue" sender:nil];
//        
//    }
//    else {
    
        
//        [self.deliveryCheckbox setImage:[UIImage imageNamed:@"Checked-checkbox.png"] forState:UIControlStateNormal];
//        [self.collectionCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
//        [self setupLayoutForOrderType];
    
    //}
    
}

- (IBAction)collectionCheckboxTapped:(id)sender {
    
    orderType = 2;
    [self.collectionCheckbox setImage:[UIImage imageNamed:@"Checked-checkbox.png"] forState:UIControlStateNormal];
    [self.deliveryCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
    
    [self setupLayoutForOrderType];
    
    [[SharedContent sharedInstance] setExtraDistanceInMiles:0.0];
    [[SharedContent sharedInstance] setExtraDistanceDeliveryCharge:0.0];
    
}

- (IBAction)cashCheckboxTapped:(id)sender {
    
    paymentType = 1;
    [self.cashCheckbox setImage:[UIImage imageNamed:@"Checked-checkbox.png"] forState:UIControlStateNormal];
    [self.paypalCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
    [self.stripeCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
    
}

- (IBAction)paypalCheckboxTapped:(id)sender {
    
    paymentType = 2;
    [self.paypalCheckbox setImage:[UIImage imageNamed:@"Checked-checkbox.png"] forState:UIControlStateNormal];
    [self.cashCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
    [self.stripeCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
    
}

- (IBAction)stripeCheckboxTapped:(id)sender {
    
    paymentType = 3;
    [self.stripeCheckbox setImage:[UIImage imageNamed:@"Checked-checkbox.png"] forState:UIControlStateNormal];
    [self.cashCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
    [self.paypalCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
    
}

- (void) setupLayoutForOrderType {
    
    self.deliveryPostcodeTxtField.text = @"";
    
    if (orderType == 1) {
        if (![[SharedContent sharedInstance] isRestoOpen]) {
            [self.requestTimeLbl setHidden:false];
            [self.requestTimeTxtField setHidden:false];
        }
        [self.deliveryPostCodeLbl setHidden:false];
        [self.deliveryPostcodeTxtField setHidden:false];
        [self.adress1Lbl setHidden:false];
        [self.address1TxtField setHidden:false];
        [self.address2Lbl setHidden:false];
        [self.address2TxtField setHidden:false];
        [self.townLbl setHidden:false];
        [self.townTxtField setHidden:false];
        
        
        self.requestTimeLblTopConstraint.constant = 8;
        
        [self.requestTimeLbl setText:@"Request Delivery Time *"];
        
        self.contentScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 900);
        
        if (![[SharedContent sharedInstance] isRestoOpen]) {
            [self setupPickerForDeliveryType];
        }
        
        
        
        
    }
    else if (orderType == 2) {
        
        if (![[SharedContent sharedInstance] isRestoOpen]) {
            [self.requestTimeLbl setHidden:false];
            [self.requestTimeTxtField setHidden:false];
        }
        [self.deliveryPostCodeLbl setHidden:true];
        [self.deliveryPostcodeTxtField setHidden:true];
        [self.adress1Lbl setHidden:true];
        [self.address1TxtField setHidden:true];
        [self.address2Lbl setHidden:true];
        [self.address2TxtField setHidden:true];
        [self.townLbl setHidden:true];
        [self.townTxtField setHidden:true];
        
        self.requestTimeLblTopConstraint.constant = -270;
        
        [self.requestTimeLbl setText:@"Request Collection Time *"];
        
        self.contentScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 545);
        
        if (![[SharedContent sharedInstance] isRestoOpen]) {
            [self setupPickerForCollectionType];
        }
        
        
    }
    else {
        
        [self.requestTimeLbl setHidden:true];
        [self.requestTimeTxtField setHidden:true];
        [self.deliveryPostCodeLbl setHidden:true];
        [self.deliveryPostcodeTxtField setHidden:true];
        [self.adress1Lbl setHidden:true];
        [self.address1TxtField setHidden:true];
        [self.address2Lbl setHidden:true];
        [self.address2TxtField setHidden:true];
        [self.townLbl setHidden:true];
        [self.townTxtField setHidden:true];
        
        
        self.requestTimeLblTopConstraint.constant = 8;
        
        [self.requestTimeLbl setText:@"Request Delivery Time *"];
        
        self.contentScrollView.contentSize = CGSizeMake(self.view.frame.size.width, 445);
    
        
    }
    
}

//- (void) setupPickerForCollectionType {
//    
//    
//    collectionReqArr = [[NSMutableArray alloc] init];
//    
//    NSDate* currentDate = [NSDate date];
//    NSDateComponents *components = [[NSCalendar currentCalendar] components:DATE_COMPONENTS fromDate:currentDate];
//    long currentWeekDay = [components weekday];
//    long currentHour = [components hour];
//    long currentMinute = [components minute];
//    
//    if (currentWeekDay == 7) {
//        currentWeekDay = currentWeekDay - 1;
//    }
//    else {
//        currentWeekDay = currentWeekDay - 2;
//    }
//    
//    NSString* str = [[[SharedContent sharedInstance] collectionTimingArr] objectAtIndex:currentWeekDay];
//    
//    long fromHour = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] firstObject] intValue];
//    long fromMinute = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] lastObject] intValue];
//    long toHour = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] firstObject] intValue];
//    long toMinute = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] lastObject] intValue];
//    
//    
//    long currentTime = (currentHour * 100) + currentMinute;
//    long fromTime = (fromHour * 100) + fromMinute;
//    long toTime = (toHour * 100) + toMinute;
//    
//    if (toTime < fromTime) {
//        
//        toTime = toTime + 2400;
//        
//    }
//    
//    if (currentTime >= 0 && currentTime <= 1300 && (currentTime > fromTime) && (currentTime < toTime)) {
//        currentTime = currentTime + 1200;
//        
//        
//    }
//    
//    long previousCurrentTime = currentTime;
//    
//    if ((currentTime > fromTime) && (currentTime < toTime)) {
//        
//        while (currentTime < toTime && previousCurrentTime <= currentTime) {
//            
//            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:currentHour andMinutes:currentMinute andType:2]  ;
//            [collectionReqArr addObject:[NSString stringWithFormat:@"Today at %@",str]];
//            
//            currentHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
//            currentMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
//            
//            previousCurrentTime = currentTime;
//            currentTime = (currentHour * 100) + currentMinute;
//            
//        }
//        
//    }
//    
//    else if ((currentTime > fromTime) && (currentTime > toTime)) {
//        
//        if (currentWeekDay == 6) {
//            currentWeekDay = 0;
//        }
//        else {
//            currentWeekDay = currentWeekDay + 1;
//        }
//        
//        NSString* tmpStr = [[[SharedContent sharedInstance] collectionTimingArr] objectAtIndex:currentWeekDay];
//        
//        fromHour = [[[[[tmpStr componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] firstObject] intValue];
//        fromMinute = [[[[[tmpStr componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] lastObject] intValue];
//        toHour = [[[[[tmpStr componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] firstObject] intValue];
//        toMinute = [[[[[tmpStr componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] lastObject] intValue];
//        
//        fromTime = (fromHour * 100) + fromMinute;
//        toTime = (toHour * 100) + toMinute;
//        
//        
//        while (fromTime < toTime) {
//            
//            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:fromHour andMinutes:fromMinute andType:2]  ;
//            [collectionReqArr addObject:[NSString stringWithFormat:@"Tomorrow at %@",str]];
//            
//            fromHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
//            fromMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
//            
//            fromTime = (fromHour * 100) + fromMinute;
//            
//        }
//        
//    }
//    
//    else if ((currentTime < fromTime) && (currentTime < toTime)) {
//        
//        while (fromTime < toTime) {
//            
//            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:fromHour andMinutes:fromMinute andType:2]  ;
//            [collectionReqArr addObject:[NSString stringWithFormat:@"Today at %@",str]];
//            
//            fromHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
//            fromMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
//            
//            fromTime = (fromHour * 100) + fromMinute;
//            
//        }
//        
//    }
//    
//        
//        selectedPickerContent = [collectionReqArr objectAtIndex: 0];
//        self.requestTimeTxtField.text = selectedPickerContent;
//    
//    //Ashwani :: Sep 14 2015
//    NSDate *date = [NSDate date];
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    df.dateFormat = @"MM/dd/yyyy";
//    
//    
//    if([[collectionReqArr objectAtIndex: 0] containsString:@"Today"])
//    {
//        NSString *time = [selectedPickerContent stringByReplacingOccurrencesOfString:@"Today at " withString:@""];
//        scheduleDateTime = [[df stringFromDate:date] stringByAppendingFormat:@" %@:00",time];
//    }
//    else
//    {
//        int daysToAdd = 1;
//        NSDate *newDate1 = [date dateByAddingTimeInterval:60*60*24*daysToAdd];
//        NSString *time = [selectedPickerContent stringByReplacingOccurrencesOfString:@"Tomorrow at " withString:@""];
//        scheduleDateTime = [[df stringFromDate:newDate1] stringByAppendingFormat:@" %@:00",time];
//    }
//    
//        picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 480, 320, 270)];
//        picker.delegate = self;
//        picker.dataSource = self;
//        picker.showsSelectionIndicator = YES;
//        
//        UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
//        [toolBar setBarStyle:UIBarStyleBlackOpaque];
//        UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        customButton.frame = CGRectMake(0, 0, 60, 33);
//        [customButton addTarget:self action:@selector(pickerViewDoneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        customButton.showsTouchWhenHighlighted = YES;
//        [customButton setTitle:@"Done" forState:UIControlStateNormal];
//        UIBarButtonItem *barCustomButton =[[UIBarButtonItem alloc] initWithCustomView:customButton];
//        UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
//        toolBar.items = [[NSArray alloc] initWithObjects:flexibleSpace,barCustomButton,nil];
//        //[picker addSubview:toolBar];
//        
//        self.requestTimeTxtField.inputView = picker;
//        self.requestTimeTxtField.inputAccessoryView = toolBar;
//        self.requestTimeTxtField.delegate = self;
//
//        
//        
//    
//    
//}

- (void) setupPickerForCollectionType {
    
    
    collectionReqArr = [[NSMutableArray alloc] init];
    isSecondTime =  NO;
    
    NSDate* currentDate = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:DATE_COMPONENTS fromDate:currentDate];
    long currentWeekDay = [components weekday];
    long currentHour = [components hour];
    long currentMinute = [components minute];
    
    if (currentWeekDay == 1) {
        currentWeekDay = 6;
    }
    else {
        currentWeekDay = currentWeekDay - 2;
    }
    
    NSString* str = [[[SharedContent sharedInstance] collectionTimingArr] objectAtIndex:currentWeekDay];
    
    long fromHour = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] firstObject] intValue];
    long fromMinute = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] lastObject] intValue];
    long toHour = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] firstObject] intValue];
    long toMinute = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] lastObject] intValue];
    
    
    long currentTime = (currentHour * 100) + currentMinute;
    long fromTime = (fromHour * 100) + fromMinute;
    long toTime = (toHour * 100) + toMinute;
    
    long nextDayFromTime = 0;
    long nextDayToTime = 0;
    long nextDayFromHour = 0;
    long nextDayFromMinute = 0;
    
    if (toTime < fromTime) {
        
        nextDayToTime = toTime;
        toTime = 2359;

        
    }
    
    
    long previousCurrentTime = currentTime;
    
    long exactCurrentTime = currentTime;
    NSString* dayStr;
    
    if ((currentTime < toTime && fromTime <= currentTime) || (currentTime < nextDayToTime && nextDayFromTime < currentTime)) {
        
        while (currentTime < toTime && fromTime <= currentTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:currentHour andMinutes:currentMinute andType:2]  ;
            
            if (exactCurrentTime > currentTime) {
                dayStr = @"Tomorrow";
            }
            else {
                dayStr = @"Today";
            }
            
            [collectionReqArr addObject:[NSString stringWithFormat:@"%@ at %@",dayStr,str]];
            
            currentHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            currentMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            currentTime = (currentHour * 100) + currentMinute;
            
            if (currentTime + collectionInterval >= 2360) {
                currentTime = 0;
                currentHour = 0;
                currentMinute = 0;
                
                if (toTime >= 2300 && toTime <= 2400) {
                    break;
                }
                
            }
            
        }
        
        while (currentTime < nextDayToTime && nextDayFromTime <= currentTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:currentHour andMinutes:currentMinute andType:2]  ;
            
            if (exactCurrentTime > currentTime) {
                dayStr = @"Tomorrow";
            }
            else {
                dayStr = @"Today";
            }
            
            [collectionReqArr addObject:[NSString stringWithFormat:@"%@ at %@",dayStr,str]];
            
            currentHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            currentMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            currentTime = (currentHour * 100) + currentMinute;
        }
    }
    
    else {
        
        while (fromTime <= toTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:fromHour andMinutes:fromMinute andType:2]  ;
            
            if (exactCurrentTime > currentTime) {
                dayStr = @"Tomorrow";
            }
            else {
                dayStr = @"Today";
            }
            
            [collectionReqArr addObject:[NSString stringWithFormat:@"%@ at %@",dayStr,str]];
            
            fromHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            fromMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            fromTime = (fromHour * 100) + fromMinute;
            
            if (fromTime >= toTime - collectionInterval) {
                break;
            }
        }
        
        while (nextDayFromTime <= nextDayToTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:nextDayFromHour andMinutes:nextDayFromMinute andType:2]  ;
            
            [collectionReqArr addObject:[NSString stringWithFormat:@"Tomorrow at %@",str]];
            
            nextDayFromHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            nextDayFromMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            nextDayFromTime = (nextDayFromHour * 100) + nextDayFromMinute;
            if (nextDayFromTime >= nextDayToTime - collectionInterval) {
                break;
            }
        }
        
    }
    
    
    selectedPickerContent = [collectionReqArr objectAtIndex: 0];
    self.requestTimeTxtField.text = selectedPickerContent;
    
    //Ashwani :: Sep 14 2015
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MM/dd/yyyy";
    
    
    if([[collectionReqArr objectAtIndex: 0] containsString:@"Today"])
    {
        NSString *time = [selectedPickerContent stringByReplacingOccurrencesOfString:@"Today at " withString:@""];
        scheduleDateTime = [[df stringFromDate:date] stringByAppendingFormat:@" %@:00",time];
    }
    else
    {
        int daysToAdd = 1;
        NSDate *newDate1 = [date dateByAddingTimeInterval:60*60*24*daysToAdd];
        NSString *time = [selectedPickerContent stringByReplacingOccurrencesOfString:@"Tomorrow at " withString:@""];
        scheduleDateTime = [[df stringFromDate:newDate1] stringByAppendingFormat:@" %@:00",time];
    }
    
    picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 480, 320, 270)];
    picker.delegate = self;
    picker.dataSource = self;
    picker.showsSelectionIndicator = YES;
    
    UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
    [toolBar setBarStyle:UIBarStyleBlackOpaque];
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.frame = CGRectMake(0, 0, 60, 33);
    [customButton addTarget:self action:@selector(pickerViewDoneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    customButton.showsTouchWhenHighlighted = YES;
    [customButton setTitle:@"Done" forState:UIControlStateNormal];
    UIBarButtonItem *barCustomButton =[[UIBarButtonItem alloc] initWithCustomView:customButton];
    UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    toolBar.items = [[NSArray alloc] initWithObjects:flexibleSpace,barCustomButton,nil];
    //[picker addSubview:toolBar];
    
    self.requestTimeTxtField.inputView = picker;
    self.requestTimeTxtField.inputAccessoryView = toolBar;
    self.requestTimeTxtField.delegate = self;
    
    
    
    
    
}

- (void) setupPickerForDeliveryType {
    
    deliveryReqArr = [[NSMutableArray alloc] init];
    isSecondTime =  NO;
    
    NSDate* currentDate = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:DATE_COMPONENTS fromDate:currentDate];
    long currentWeekDay = [components weekday];
    long currentHour = [components hour];
    long currentMinute = [components minute];
    
    if (currentWeekDay == 1) {
        currentWeekDay = 6;
    }
    else {
        currentWeekDay = currentWeekDay - 2;
    }
    
    NSString* str = [[[SharedContent sharedInstance] deliveryTimingArr] objectAtIndex:currentWeekDay];
    
    long fromHour = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] firstObject] intValue];
    long fromMinute = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] lastObject] intValue];
    long toHour = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] firstObject] intValue];
    long toMinute = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] lastObject] intValue];
    
    long currentTime = (currentHour * 100) + currentMinute;
    long fromTime = (fromHour * 100) + fromMinute;
    long toTime = (toHour * 100) + toMinute;
    
    long nextDayFromTime = 0;
    long nextDayToTime = 0;
    long nextDayFromHour = 0;
    long nextDayFromMinute = 0;
    
    if (toTime < fromTime) {
        
        nextDayToTime = toTime;
        toTime = 2359;
        
        
    }
    

    long previousCurrentTime = currentTime;

    long exactCurrentTime = currentTime;
    NSString* dayStr;
    
    if ((currentTime < toTime && fromTime <= currentTime) || (currentTime < nextDayToTime && nextDayFromTime < currentTime)) {
        
        while (currentTime < toTime && fromTime <= currentTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:currentHour andMinutes:currentMinute andType:1]  ;
            
            if (exactCurrentTime > currentTime) {
                dayStr = @"Tomorrow";
            }
            else {
                dayStr = @"Today";
            }
            
            [deliveryReqArr addObject:[NSString stringWithFormat:@"%@ at %@",dayStr,str]];
            
            currentHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            currentMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            currentTime = (currentHour * 100) + currentMinute;
            
            if (currentTime + deliverInterval >= 2360) {
                currentTime = 0;
                currentHour = 0;
                currentMinute = 0;
                
                if (toTime >= 2300 && toTime <= 2400) {
                    break;
                }
            }
        }
        
        while (currentTime < nextDayToTime && nextDayFromTime <= currentTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:currentHour andMinutes:currentMinute andType:1]  ;
            
            if (exactCurrentTime > currentTime) {
                dayStr = @"Tomorrow";
            }
            else {
                dayStr = @"Today";
            }
            
            [deliveryReqArr addObject:[NSString stringWithFormat:@"%@ at %@",dayStr,str]];
            
            currentHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            currentMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            currentTime = (currentHour * 100) + currentMinute;
        }
    }
    
    else {
        
        while (fromTime <= toTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:fromHour andMinutes:fromMinute andType:1]  ;
            
            if (exactCurrentTime > currentTime) {
                dayStr = @"Tomorrow";
            }
            else {
                dayStr = @"Today";
            }
            
            [deliveryReqArr addObject:[NSString stringWithFormat:@"%@ at %@",dayStr,str]];
            
            fromHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            fromMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            fromTime = (fromHour * 100) + fromMinute;
            
            if (fromTime >= toTime - deliverInterval) {
                break;
            }
            
        }
        
        while (nextDayFromTime <= nextDayToTime) {
            
            NSString*str = [self getCollectionNextHourAndTimeForCurrentHour:nextDayFromHour andMinutes:nextDayFromMinute andType:1]  ;
            
            [deliveryReqArr addObject:[NSString stringWithFormat:@"Tomorrow at %@",str]];
            
            nextDayFromHour = [[[str componentsSeparatedByString:@":"] firstObject] intValue];
            nextDayFromMinute = [[[str componentsSeparatedByString:@":"] lastObject] intValue];
            
            previousCurrentTime = currentTime;
            nextDayFromTime = (nextDayFromHour * 100) + nextDayFromMinute;
            
            if (nextDayFromTime >= nextDayToTime - deliverInterval) {
                break;
            }
        }
        
    }
    
    
    
    
        selectedPickerContent1 = [deliveryReqArr objectAtIndex: 0];
        //Ashwani :: Sep 14 2015
        NSDate *date = [NSDate date];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"MM/dd/yyyy";
    
    
        if([[deliveryReqArr objectAtIndex: 0] containsString:@"Today"])
        {
            NSString *time = [selectedPickerContent1 stringByReplacingOccurrencesOfString:@"Today at " withString:@""];
            scheduleDateTime = [[df stringFromDate:date] stringByAppendingFormat:@" %@:00",time];
        }
        else
        {
            int daysToAdd = 1;
            NSDate *newDate1 = [date dateByAddingTimeInterval:60*60*24*daysToAdd];
            NSString *time = [selectedPickerContent1 stringByReplacingOccurrencesOfString:@"Tomorrow at " withString:@""];
            scheduleDateTime = [[df stringFromDate:newDate1] stringByAppendingFormat:@" %@:00",time];
        }
    
        self.requestTimeTxtField.text = selectedPickerContent1;
        
        picker1 = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 480, 320, 270)];
        picker1.delegate = self;
        picker1.dataSource = self;
        picker1.showsSelectionIndicator = YES;
        
        UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
        [toolBar setBarStyle:UIBarStyleBlackOpaque];
        UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
        customButton.frame = CGRectMake(0, 0, 60, 33);
        [customButton addTarget:self action:@selector(deliveryPickerViewDoneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        customButton.showsTouchWhenHighlighted = YES;
        [customButton setTitle:@"Done" forState:UIControlStateNormal];
        UIBarButtonItem *barCustomButton =[[UIBarButtonItem alloc] initWithCustomView:customButton];
        UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        toolBar.items = [[NSArray alloc] initWithObjects:flexibleSpace,barCustomButton,nil];
        //[picker addSubview:toolBar];
        
        self.requestTimeTxtField.inputView = picker1;
        self.requestTimeTxtField.inputAccessoryView = toolBar;
        self.requestTimeTxtField.delegate = self;
    
}


-(NSString *) getCollectionNextHourAndTimeForCurrentHour:(long) hour andMinutes:(long) minute andType:(int)type {
    
    NSString* retStr;
    
    if (minute == 15 || minute == 30 || minute == 45 || minute == 00) {
        
        if (type == 1) {
            minute = minute + deliverInterval;
        }
        else {
            minute = minute + collectionInterval;
        }
        
    }
    else {
        
        if (!isSecondTime) {
            if (minute < 15) {
                minute = 15;
            }
            else if (minute < 30) {
                minute = 30;
            }
            else if (minute < 45) {
                minute = 45;
            }
            else if (minute < 60) {
                minute = 00;
                hour++;
            }
            
            isSecondTime =  YES;
        }
        
        
        
        if (type == 1) {
            minute = minute + deliverInterval;
        }
        else {
            minute = minute + collectionInterval;
        }
    }
    
    if (minute>59) {
        minute = minute - 60;
        hour = hour + 1;
        
        if (hour > 23) {
            hour = hour - 24;
        }
    }
    
    NSString* hourStr = [NSString stringWithFormat:@"%ld",hour];
    NSString* minuteStr = [NSString stringWithFormat:@"%ld",minute];
    
    if (hour < 10) {
        hourStr = [NSString stringWithFormat:@"0%ld",hour];
    }
    if (minute < 10) {
        minuteStr = [NSString stringWithFormat:@"0%ld",minute];
    }
    
    retStr = [NSString stringWithFormat:@"%@:%@",hourStr,minuteStr];
    
    return retStr;
    
}

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonTapped:(id)sender {
    
    if ([self isFormValid]) {
        
        [[SharedContent sharedInstance] setOrderDetailsDict:[self prepareDictionarForOrderDetails]];
        [self performSegueWithIdentifier:@"showPersonalDetailsSegue" sender:nil];
        
        
    }
    else {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Invalid Details" message:@"Please check the form and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
    }
}



//Ashwani :: Set here for check
- (NSString *) getTotalPrice {
    
    double price = 0.0;
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    tmpArr  = [[[SharedContent sharedInstance] cartArr] valueForKey:@"Price"];
    
    for (int i = 0; i < tmpArr.count; i++) {
        
        price = price + [[tmpArr objectAtIndex:i] doubleValue];
    }
    
    return [NSString stringWithFormat:@"£%.2f",price];
    
}

- (BOOL) validateMinimumOrderAmount_new {
    
    if ([[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] < [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"] floatValue]) {
        
        return false;
    }
    return true;
}

- (BOOL) validateFreeDeliveryThreshold {
    
    if ([[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] < [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]) {
        
        return false;
    }
    return true;
}

- (BOOL) isFormValid {
    
    if (orderType == 1) {
        
        if (paymentType == 0) {
            return false;
        }
        if ([self.address1TxtField.text isEqualToString:@""]) {
            return false;
        }
        if ([self.townTxtField.text isEqualToString:@""]) {
            return false;
        }
        if (isDeliveryPostalCodeInvalid == 0 || isDeliveryPostalCodeInvalid == 1) {
            return false;
        }
        
        return true;
        
    }
    else if (orderType == 2) {
        
        if (paymentType == 0) {
            return false;
        }
        
        return true;
        
    }
    
    return false;
    
}

- (NSMutableDictionary *) prepareDictionarForOrderDetails {
    
    NSString* paymentStr = @"";
    
    switch (paymentType) {
        case 1:
            paymentStr = @"Cash";
            break;
        case 2:
            paymentStr = @"Paypal";
            break;
        case 3:
            paymentStr = @"Card";
            break;
            
        default:
            break;
    }
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:[NSString stringWithFormat:@"%@\n\n\niOS\n%@",self.instructionsTextView.text,paymentStr] forKey:@"instructions"];
    [dict setObject:[NSNumber numberWithInt:orderType] forKey:@"orderType"];
    [dict setObject:[NSNumber numberWithInt:paymentType] forKey:@"paymentType"];
    
    [dict setObject:self.deliveryPostcodeTxtField.text forKey:@"postCode"];
    [dict setObject:self.address1TxtField.text forKey:@"address1"];
    [dict setObject:self.address2TxtField.text forKey:@"address2"];
    [dict setObject:self.townTxtField.text forKey:@"townCity"];
    
    //Ashwani :: Replace string with time string of format MM/dd/yyyy HH:mm:ss
    
    if (!scheduleDateTime) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
        scheduleDateTime = [df stringFromDate:[NSDate date]];
    }
    
    [dict setObject:scheduleDateTime forKey:@"requestTime"];
    //[dict setObject:self.requestTimeTxtField.text forKey:@"requestTime"];
    
    return dict;
    
}


-(void)pickerViewDoneButtonTapped:(id)sender{
    NSLog(@"Done tapped");
    [picker1 removeFromSuperview];
    self.requestTimeTxtField.text = selectedPickerContent;
    [self.view endEditing:YES];
}

-(void)deliveryPickerViewDoneButtonTapped:(id)sender{
    NSLog(@"Done tapped");
    self.requestTimeTxtField.text = selectedPickerContent1;
    [self.view endEditing:YES];
}


#pragma mark - PICKERVIEW DELEGATE AND DATASOURCE

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    if (pickerView == picker1) {
        return [deliveryReqArr count];
    }
    return [collectionReqArr count];
}

// Display each row's data.
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    
    if (pickerView == picker1) {
        return [deliveryReqArr objectAtIndex:row];
    }
    return [collectionReqArr objectAtIndex:row];
}

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    
    //Ashwani :: Sep 14 2015
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"MM/dd/yyyy";
    if (pickerView == picker) {
        NSLog(@"You selected this: %@", [collectionReqArr objectAtIndex:row]);
        selectedPickerContent = [collectionReqArr objectAtIndex:row];
        if([selectedPickerContent containsString:@"Today"])
        {
            scheduleDateTime = [[df stringFromDate:date] stringByAppendingFormat:@" %@:00",[selectedPickerContent stringByReplacingOccurrencesOfString:@"Today at " withString:@""]];
        }
        else
        {
            int daysToAdd = 1;
            NSDate *newDate1 = [date dateByAddingTimeInterval:60*60*24*daysToAdd];
            scheduleDateTime = [[df stringFromDate:newDate1] stringByAppendingFormat:@" %@:00",[selectedPickerContent stringByReplacingOccurrencesOfString:@"Today at " withString:@""]];
        }
    }
    else {
        NSLog(@"You selected this: %@", [deliveryReqArr objectAtIndex:row]);
        selectedPickerContent1 = [deliveryReqArr objectAtIndex:row];
        if([selectedPickerContent1 containsString:@"Today"])
        {
            scheduleDateTime = [[df stringFromDate:date] stringByAppendingFormat:@" %@:00",[selectedPickerContent1 stringByReplacingOccurrencesOfString:@"Today at " withString:@""]];
        }
        else
        {
            int daysToAdd = 1;
            NSDate *newDate1 = [date dateByAddingTimeInterval:60*60*24*daysToAdd];
            scheduleDateTime = [[df stringFromDate:newDate1] stringByAppendingFormat:@" %@:00",[selectedPickerContent1 stringByReplacingOccurrencesOfString:@"Today at " withString:@""]];
        }
    }
    
}

#pragma mark - TEXT FIELD DELEGATES

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.center.y>500 && showKeyboardAnimation) {
        CGPoint MyPoint = self.view.center;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             
                             self.view.center = CGPointMake(MyPoint.x, MyPoint.y - textField.center.y + 500);
                         }];
        
        showKeyboardAnimation=TRUE;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
    if (textField.tag == 101) {
        
//        [self calculateDistance:textField.text];
        [self validateDeliveryChargesForPostCode:textField.text];
        
    }
    
    if (showKeyboardAnimation) {
        //CGPoint MyPoint = self.view.center;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             
                             self.view.center = CGPointMake(viewCenter.x, viewCenter.y);
                         }];
        
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self scrollTouch];
    return YES;
}

- (void) scrollTouch {
    
    showKeyboardAnimation = true;
    [self.view endEditing:YES];
    
}



//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    
//    [self scrollTouch];
//    
//}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self scrollTouch];
}

- (void) validateDeliveryChargesForPostCode:(NSString *)postalCode {
    
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"]];
    
    if ([[dict allKeys] containsObject:@"_xsi:type"]) {
        
        CGFloat finalAmount = [[[[orderTotal componentsSeparatedByString:@" "] lastObject] stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue];
        
        NSString* finalPostCode = [[postalCode stringByReplacingOccurrencesOfString:@" " withString:@""] substringToIndex:postalCode.length-3];
        
        NSMutableArray* postcodeArr = [[NSMutableArray alloc] initWithArray:[[dict valueForKey:@"Areas"] valueForKey:@"DeliveryArea"]];
        
        int flag = 0;
        int i = 0;
        for (NSDictionary* postcodeDict in postcodeArr) {
            
            if ([[[postcodeDict valueForKey:@"Postcode"] lowercaseString] isEqualToString:[finalPostCode lowercaseString]]) {
                
                flag = 1;
                break;
                
            }
            i++;
            
        }
        
        if (flag == 1) {
            
            NSDictionary* postcodeDict = [postcodeArr objectAtIndex:i];
            
            if (finalAmount < [[postcodeDict valueForKey:@"MinimumDeliveryThreshold"] floatValue]) {
                isDeliveryPostalCodeInvalid = 0;
                [self.invalidPostcodeLbl setHidden:false];
                [self.invalidPostcodeLbl setFont:[UIFont boldSystemFontOfSize:9.0]];
                [self.invalidPostcodeLbl setText:[NSString stringWithFormat:@"Sorry ! You need to add product worth £%@ to yor cart for delivery option.",[postcodeDict valueForKey:@"MinimumDeliveryThreshold"]]];
            }
            else if (finalAmount >= [[postcodeDict valueForKey:@"MinimumDeliveryThreshold"] floatValue] && finalAmount < [[postcodeDict valueForKey:@"FreeDeliveryThreshold"] floatValue]) {
                isDeliveryPostalCodeInvalid = 2;
                [self.invalidPostcodeLbl setHidden:true];
                [[SharedContent sharedInstance] setExtraDistanceDeliveryCharge:[[postcodeDict valueForKey:@"DeliveryCharge"] floatValue]];
                [[SharedContent sharedInstance] setExtraDistanceInMiles:0.0];
            }
            else {//if (finalAmount >= [[postcodeDict valueForKey:@"FreeDeliveryThreshold"] floatValue]) {
                isDeliveryPostalCodeInvalid = 2;
                [self.invalidPostcodeLbl setHidden:true];
                [[SharedContent sharedInstance] setExtraDistanceDeliveryCharge:0.0];
                [[SharedContent sharedInstance] setExtraDistanceInMiles:0.0];
            }
            
        }
        else {
            isDeliveryPostalCodeInvalid = 0;
            [self.invalidPostcodeLbl setHidden:false];
            [self.invalidPostcodeLbl setFont:[UIFont boldSystemFontOfSize:9.0]];
            [self.invalidPostcodeLbl setText:@"Sorry ! Your post code is out of range !"];
        }
        
        
    }
    else {
        [self calculateDistance:postalCode];
    }
    
}

- (void) calculateDistance:(NSString *)toPostalCode {
    
    
    [SVProgressHUD showWithStatus:@"Verifying Postcode"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *urlPath = [NSString stringWithFormat:@"/maps/api/distancematrix/json?origins=%@&destinations=%@&mode=driving&language=en-EN&sensor=false" ,[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"Postcode"] , toPostalCode];
        NSURL *url = [[NSURL alloc]initWithScheme:@"http" host:@"maps.googleapis.com" path:urlPath];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
        [request setURL:url];
        [request setHTTPMethod:@"GET"];
        
        NSURLResponse *response ;
        NSError *error;
        NSData *data;
        data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        NSMutableDictionary *jsonDict= (NSMutableDictionary*)[NSJSONSerialization  JSONObjectWithData:data options:kNilOptions error:&error];
        
        if ([[jsonDict valueForKey:@"status"] isEqualToString:@"OK"]) {
            
            NSMutableDictionary *newdict=[jsonDict valueForKey:@"rows"];
            NSArray *elementsArr=[newdict valueForKey:@"elements"];
            NSArray *arr=[elementsArr objectAtIndex:0];
            NSDictionary *dict=[arr objectAtIndex:0];
            NSMutableDictionary *distanceDict=[dict valueForKey:@"distance"];
            NSLog(@"distance:%ld KMS",[[distanceDict valueForKey:@"value"] longValue]);
            
            if (distanceDict) {
                int maxRaduis = [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"MaxRadius"] intValue];
                
                if ((float)[[distanceDict valueForKey:@"value"] longValue] / 1000.0 > (float)(maxRaduis * 1.60934)) {
                    isDeliveryPostalCodeInvalid = 1;
                }
                else {
                    isDeliveryPostalCodeInvalid = 2;
                    
                    float milesDiff = (float)([[distanceDict valueForKey:@"value"] longValue] / 1609.34) - (float)[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeRadius"] intValue];
                    if (milesDiff > 0) {
                        
                        milesDiff = ceilf(milesDiff);
                        
                        float extraCharge = milesDiff * (float)[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"ChargePerMile"] intValue];
                        [[SharedContent sharedInstance] setExtraDistanceDeliveryCharge:extraCharge];
                        [[SharedContent sharedInstance] setExtraDistanceInMiles:milesDiff];
                        
                    }
                    
                }
            }
            else {
                isDeliveryPostalCodeInvalid = 0;
            }
            
        }
        else {
            isDeliveryPostalCodeInvalid = 0;
        }
        
        

        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            if (isDeliveryPostalCodeInvalid == 2) {
                [self.invalidPostcodeLbl setHidden:true];
            }
            else {
                if (isDeliveryPostalCodeInvalid == 0) {
                    
                    [self.invalidPostcodeLbl setFont:[UIFont boldSystemFontOfSize:13.0]];
                    [self.invalidPostcodeLbl setText:@"Invalid Postcode"];
                    
                }
                else {
                    
                    [self.invalidPostcodeLbl setFont:[UIFont boldSystemFontOfSize:9.0]];
                    [self.invalidPostcodeLbl setText:@"Sorry ! Your post code is out of range ! Please select Collection and the time for the same."];
                    
                }
                [self.invalidPostcodeLbl setHidden:false];
            }
            
            
        });
    });
}

- (BOOL) validateMinimumOrderAmount {
    
    if (orderType == 1) {
        
        if ([[[[orderTotal componentsSeparatedByString:@" "] lastObject] stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] < [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"] floatValue]) {
            return true;
        }
        return false;
    }
    return false;
}

- (void) refreshFinalOrder {
    
    double price = 0.0;
    
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    tmpArr  = [[[SharedContent sharedInstance] cartArr] valueForKey:@"Price"];
    
    for (int i = 0; i < tmpArr.count; i++) {
        
        price = price + [[tmpArr objectAtIndex:i] doubleValue];
        
    }
    
    if (price>0.0) {
        orderTotal = [NSString stringWithFormat:@"Order £%.2f",price];
    }
    else {
        orderTotal = [NSString stringWithFormat:@"Order £0.00"];
    }
    

}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"orderTimeAlertSegue"]) {
        
        OrderDetailsAlertViewController* controller = (OrderDetailsAlertViewController *)[segue destinationViewController];
        
        controller.txt = [NSString stringWithFormat:@"Please add more items to make total order amount upto £%@",[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"]];

        
        
        MZFormSheetSegue *formSheetSegue = (MZFormSheetSegue *)segue;
        MZFormSheetController *formSheet = formSheetSegue.formSheetController;
        formSheet.transitionStyle = MZFormSheetTransitionStyleBounce;
        formSheet.cornerRadius = 8.0;
        
        NSString *deviceType = [UIDevice currentDevice].model;
        
        if([deviceType hasPrefix:@"iPad"])
        {
            formSheet.presentedFormSheetSize = CGSizeMake(600, 400);
        }
        else {
            formSheet.presentedFormSheetSize = CGSizeMake(300, 200);
        }
        
        formSheet.didTapOnBackgroundViewCompletionHandler = ^(CGPoint location) {
        };
        
        formSheet.shadowRadius = 2.0;
        formSheet.shadowOpacity = 0.3;
        formSheet.shouldDismissOnBackgroundViewTap = YES;
        formSheet.shouldCenterVertically = YES;
        
        
        formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
            [self handleAlertDismissal];
        };
        
    }
    
}

-(void) handleAlertDismissal {
    
    
    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
    
    
}

#pragma mark - Alert View Delegate -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100)
    {
        if(buttonIndex == 0)
        {
            [self.deliveryCheckbox setImage:[UIImage imageNamed:@"Checked-checkbox.png"] forState:UIControlStateNormal];
            [self.collectionCheckbox setImage:[UIImage imageNamed:@"unchecked_checkbox.png"] forState:UIControlStateNormal];
            [self setupLayoutForOrderType];
        }
        else
        {
            NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
            for (UIViewController *aViewController in allViewControllers) {
                if ([aViewController isKindOfClass:[OrderViewController class]]) {
                    [self.navigationController popToViewController:aViewController animated:YES];
                }
            }
        }
    }
    
    if(alertView.tag == 200)
    {
        if(buttonIndex == 0)
        {
            NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
            for (UIViewController *aViewController in allViewControllers) {
                if ([aViewController isKindOfClass:[OrderViewController class]]) {
                    [self.navigationController popToViewController:aViewController animated:YES];
                }
            }
        }
    }
}

#pragma mark - Text View Delegate -
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if(self.instructionsTextView)
        [self.instructionsTextView endEditing:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}


@end
