//
//  ConfirmOrderViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "ConfirmOrderViewController.h"

@interface ConfirmOrderViewController ()

@property(nonatomic, strong, readwrite) PayPalConfiguration *payPalConfig;

@end

@implementation ConfirmOrderViewController

NSString *letters = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    itemArr = [[NSMutableArray alloc] init];
    itemArr = [[SharedContent sharedInstance] cartArr];
    
    self.itemTblView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.itemTblView.layer.borderWidth = 1.0;
    self.itemTblView.layer.cornerRadius = 5.0;
    
    [self setupInitalView];

    
    // Set up payPalConfig
    _payPalConfig = [[PayPalConfiguration alloc] init];
    _payPalConfig.acceptCreditCards = YES;
    _payPalConfig.merchantName = @"W4Fire Pizza";
    
    NSLog(@"Email : %@", [[SharedContent sharedInstance] PaypalEmail]);
//    if([[SharedContent sharedInstance] PaypalEmail] != (id)[NSNull null])
//    {
//        _payPalConfig.defaultUserEmail = [[SharedContent sharedInstance] PaypalEmail];
//    }
//    else
        _payPalConfig.defaultUserEmail = @"";
    
    _payPalConfig.merchantPrivacyPolicyURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/privacy-full"];
    _payPalConfig.merchantUserAgreementURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/useragreement-full"];
    
    // Setting the languageOrLocale property is optional.
    //
    // If you do not set languageOrLocale, then the PayPalPaymentViewController will present
    // its user interface according to the device's current language setting.
    //
    // Setting languageOrLocale to a particular language (e.g., @"es" for Spanish) or
    // locale (e.g., @"es_MX" for Mexican Spanish) forces the PayPalPaymentViewController
    // to use that language/locale.
    //
    // For full details, including a list of available languages and locales, see PayPalPaymentViewController.h.
    
    _payPalConfig.languageOrLocale = [NSLocale preferredLanguages][0];
    
    // Setting the payPalShippingAddressOption property is optional.
    // See PayPalConfiguration.h for details.
    _payPalConfig.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
    
    //Ashwani :: Set sandbox mode
    [PayPalMobile preconnectWithEnvironment:PayPalEnvironmentProduction];
    //[PayPalMobile preconnectWithEnvironment:PayPalEnvironmentSandbox];
    
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stripePaymentSuccess) name:@"StripePaymentSuccessNotification" object:nil];
    
}

- (void) setupInitalView {
    
    //*********************   START    ***********************************//
    
    subTotal = @"";
    discountRate = @"";
    grandTotal = @"";
    
    //Ashwani :: Nov 06 send ordertotal
    NSMutableDictionary* dictSettings = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    //Ashwani :: Nov 05, 2015 Add discount offer info here for Get Discount
    float DiscountRate = [[dictSettings valueForKey:@"DiscountRate"] floatValue];
    DiscountRate = DiscountRate*100;
    NSString *DiscountPercentage = [dictSettings valueForKey:@"DiscountRate"];
    NSString *MinimumRateForDiscount = [dictSettings valueForKey:@"DiscountThreshold"];
    
    double calculatedPrice = [[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] doubleValue];
    double minimumAmountForDiscount = [MinimumRateForDiscount doubleValue];
    if([DiscountPercentage floatValue] > 0)
    {
        //Ashwani :: Nov 05, 2015 get here price of discount for
        if(calculatedPrice >= minimumAmountForDiscount)
        {
            double discountPrice = calculatedPrice*[DiscountPercentage doubleValue];
            double totalPrice = calculatedPrice-discountPrice;
            
            subTotal = [NSString stringWithFormat:@"£%.2f",calculatedPrice];
            discountRate = [NSString stringWithFormat:@"£%.2f",discountPrice];
            grandTotal = [NSString stringWithFormat:@"£%.2f",totalPrice];
        }
        else
        {
            subTotal = [self getTotalPrice];
            discountRate = @"£0.0";
            grandTotal = [self getTotalPrice];
            
        }
    }
    else
    {
        subTotal = [self getTotalPrice];
        discountRate = @"0.0";
        grandTotal = [self getTotalPrice];
    }
    
    //Ashwani :: Nov 17 2015 Check here for ordertype and threshold
    if([[[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"orderType"] stringValue] isEqualToString:@"1"])
    {
        if(![self validateFreeDeliveryThreshold])
            grandTotal = [NSString stringWithFormat:@"£%.2f",[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]];
    }
    
    grandTotal = [NSString stringWithFormat:@"£%.2f",([[grandTotal stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] + [[SharedContent sharedInstance] extraDistanceDeliveryCharge])];
    
    self.totalPriceLbl.text = grandTotal;
    //*********************END***************************
    
    //self.totalPriceLbl.text = [self getTotalPrice];
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict = [[SharedContent sharedInstance] orderDetailsDict];
    
    if ([[dict valueForKey:@"instructions"] isEqualToString:@""]) {
        self.instructionLbl.text = @"None";
    }
    else {
        self.instructionLbl.text = [dict valueForKey:@"instructions"];
    }
    
    if ([[dict valueForKey:@"orderType"] intValue] == 1) {
        
        self.orderTypeHeadingLbl.text = @"Delivery Details";
        self.orderTypeSubHeadingLbl.text = @"Delivery Request";
        
    }
    else {
        
        self.orderTypeHeadingLbl.text = @"Colection Details";
        self.orderTypeSubHeadingLbl.text = @"Collection Request";
        
    }
    
     NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
    NSDate *date = [df dateFromString:[dict valueForKey:@"requestTime"]];
    
    [df setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    NSString *strDate = [df stringFromDate:date];
    
    self.orderTypeValueLbl.text = strDate;
    
}

//Ashwani :: Nov 17 2015 set here for total price check
- (BOOL) validateFreeDeliveryThreshold {
    
    if ([[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] < [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]) {
        
        return false;
    }
    return true;
}

- (NSString *) getTotalPrice {
    
    double price = 0.0;
    
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    tmpArr  = [[[SharedContent sharedInstance] cartArr] valueForKey:@"Price"];
    
    for (int i = 0; i < tmpArr.count; i++) {
        
        price = price + [[tmpArr objectAtIndex:i] doubleValue];
        
    }
    
    return [NSString stringWithFormat:@"£%.2f",price];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) refreshViewForConfirmOrder {
    
    
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonTapped:(id)sender {
    
    NSLog(@"orderDetailsDict is : %@", [[SharedContent sharedInstance] orderDetailsDict]);
    if ([[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"paymentType"] intValue] == 2)
    {
        resultText = @"";
        
        // Note: For purposes of illustration, this example shows a payment that includes
        //       both payment details (subtotal, shipping, tax) and multiple items.
        //       You would only specify these if appropriate to your situation.
        //       Otherwise, you can leave payment.items and/or payment.paymentDetails nil,
        //       and simply set payment.amount to your total charge.
        
        // Optional: include multiple items
        
        
        NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
        NSMutableArray* items = [[NSMutableArray alloc] init];
        tmpArr  = [[SharedContent sharedInstance] cartArr];
        
        NSMutableDictionary* settings = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
        float DisRate = [[settings valueForKey:@"DiscountRate"] floatValue];
        DisRate = DisRate*100;
        
        NSString *DisPerc = [settings valueForKey:@"DiscountRate"];
        NSString *MinDiscount = [settings valueForKey:@"DiscountThreshold"];
        double minAmountForDis = 0.00f;
        minAmountForDis = [MinDiscount doubleValue];
        
        NSLog(@"Tot price : %@", [self getTotalPrice]);
        
        
        
        for (int i = 0; i<tmpArr.count; i++) {
            
            NSString *price = [[tmpArr objectAtIndex:i] valueForKey:@"Price"];;
            if([DisPerc floatValue] > 0 && ([[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] >= minAmountForDis))
            {
                double discountPrice = [[[tmpArr objectAtIndex:i] valueForKey:@"Price"] floatValue]*[DisPerc doubleValue];
                double totalPrice = [[[tmpArr objectAtIndex:i] valueForKey:@"Price"] floatValue]-discountPrice;
                price = [NSString stringWithFormat:@"%.02f", totalPrice];
            }
            
            
            price = [NSString stringWithFormat:@"%.02f",[price floatValue] + [[SharedContent sharedInstance] extraDistanceDeliveryCharge]];
            
            
            //withPrice:[NSDecimalNumber decimalNumberWithString:[[tmpArr objectAtIndex:i] valueForKey:@"Price"]]
            PayPalItem *item = [PayPalItem itemWithName:[[tmpArr objectAtIndex:i] valueForKey:@"Name"]
                                           withQuantity:1
                                              withPrice:[NSDecimalNumber decimalNumberWithString:price]
                                           withCurrency:@"GBP"
                                                withSku:[NSString stringWithFormat:@"DJ-%d",i ]];
            
            [items addObject:item];
            
        }
        
        
        NSDecimalNumber *subtotal = [PayPalItem totalPriceForItems:items];
        
        // Optional: include payment details
        NSDecimalNumber *shipping = [[NSDecimalNumber alloc] initWithString:@"0.00"];
        NSDecimalNumber *tax = [[NSDecimalNumber alloc] initWithFloat:[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"ElectronicPaymentCharge"] floatValue]];
        PayPalPaymentDetails *paymentDetails = [PayPalPaymentDetails paymentDetailsWithSubtotal:subtotal
                                                                                   withShipping:shipping
                                                                                        withTax:tax];
        NSDecimalNumber *total = [[subtotal decimalNumberByAdding:shipping] decimalNumberByAdding:tax];
        
        PayPalPayment *payment = [[PayPalPayment alloc] init];
        payment.amount = total;
        //payment.currencyCode = @"GBP";
        payment.currencyCode = @"GBP";
        payment.shortDescription = @"W4Fire Pizza Food Order";
        payment.items = items;  // if not including multiple items, then leave payment.items as nil
        payment.paymentDetails = paymentDetails; // if not including payment details, then leave payment.paymentDetails as nil
        
        if (!payment.processable) {
            // This particular payment will always be processable. If, for
            // example, the amount was negative or the shortDescription was
            // empty, this payment wouldn't be processable, and you'd want
            // to handle that here.
        }
        
        // Update payPalConfig re accepting credit cards.
        self.payPalConfig.acceptCreditCards = true;
        
        PayPalPaymentViewController *paymentViewController = [[PayPalPaymentViewController alloc] initWithPayment:payment
                                                                                                    configuration:self.payPalConfig
                                                                                                         delegate:self];
       // [self.navigationController presentViewController:paymentViewController animated:YES completion:nil];
        [self presentViewController:paymentViewController animated:YES completion:nil];
        
    }
    
    else if ([[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"paymentType"] intValue] == 3) {
        
        [self performSegueWithIdentifier:@"showStripeSegue" sender:nil];
        
    }
    
    else {
        //Aswhani :: Update data
        [self updateOrderedDataOnServer];
        //[self performSegueWithIdentifier:@"showOrderReceiptSegue" sender:nil];
    }
    
    
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [itemArr count];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"itemCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"itemCell"];
    }
    
    [cell.textLabel setFont:[UIFont systemFontOfSize:13.0]];
    [cell.detailTextLabel setFont:[UIFont systemFontOfSize:13.0]];
    
    //Ashwani :: March 02 2016 Changes Made to show data in correct format
    if([[[itemArr objectAtIndex:indexPath.row] allKeys] containsObject:@"ProductVariantName"])
    {
        cell.textLabel.text = [[[itemArr objectAtIndex:indexPath.row] valueForKey:@"Name"] stringByAppendingFormat:@" (%@)",[[itemArr objectAtIndex:indexPath.row] valueForKey:@"ProductVariantName"]];
    }
    else
    {
        cell.textLabel.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Name"] ;
    }
    
    
    //cell.textLabel.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Name"];
    cell.detailTextLabel.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Price"];
    
    return cell;
    
}


#pragma mark PayPalPaymentDelegate methods

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    NSLog(@"PayPal Payment Success!");
    NSLog(@"PayPal Payment Details : %@",completedPayment.paymentDetails);
    
    NSLog(@"Confirmation : %@", completedPayment.confirmation);
    //NSMutableDictionary *dictConf = [[NSMutableDictionary alloc] init];
   // dictConf = completedPayment.confirmation;
    
    NSMutableDictionary *dictRes = [[NSMutableDictionary alloc] init];
    dictRes = [completedPayment.confirmation valueForKey:@"response"];
    
    //resultText = [completedPayment description];
    //resultText = [dictRes valueForKey:@"state"];
    resultText = @"NULL";
    isOrderConfirmed = true;
    PayPalData =@"NULL" ;
    PayPalPayerID=[self randomStringWithLength:13] ;
    PaypalPaymentId=[dictRes valueForKey:@"id"];
    PayPalSaleID=@"NULL";
    clientIP = @"NULL";
    
    [self sendCompletedPaymentToServer:completedPayment]; // Payment was processed successfully; send to server for verification and fulfillment
    [self dismissViewControllerAnimated:YES completion:nil];
    
    

    [SVProgressHUD showSuccessWithStatus:@"Payment successful"];
    [self updateOrderedDataOnServer];
    //Ashwani ::  Done Payment process then update request data on server
    
    
}

- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    NSLog(@"PayPal Payment Canceled");
    resultText = @"";
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [SVProgressHUD showErrorWithStatus:@"Payment Cancelled"];
}

#pragma mark Proof of payment validation

- (void)sendCompletedPaymentToServer:(PayPalPayment *)completedPayment {
    // TODO: Send completedPayment.confirmation to server
    NSLog(@"Here is your proof of payment:\n\n%@\n\nSend this to your server for confirmation and fulfillment.", completedPayment.confirmation);
    
    
}

//Ashwani :: Updatiing database after completeing payment
-(void) updateOrderedDataOnServer {
    
    [SVProgressHUD showWithStatus:@"Processing Order"];
    
    //Ashwani :: Oct 30 2015 START Set current date here as per the changes required
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *date = [NSDate date];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"];
    
    orderDateTime = [dateFormatter stringFromDate:date];
    scheduleDateTime = [self getScheduledDateTimeForPoller];
    
    NSString * orderXML = [self createOrderXML];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if(clientIP == nil)
        [dict setObject:[NSNull null] forKey:@"ClientIp"];
    else
        [dict setObject:clientIP forKey:@"ClientIp"];
    
    [dict setObject:orderDateTime forKey:@"OrderDateTime"];
    
    [dict setObject:[subTotal stringByReplacingOccurrencesOfString:@"£" withString:@""] forKey:@"SubTotal"];
    [dict setObject:[discountRate stringByReplacingOccurrencesOfString:@"£" withString:@""] forKey:@"DiscountPrice"];
    
    
    [dict setObject:orderXML forKey:@"OrderXml"];
    
    if ([[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"paymentType"] intValue] == 2 || [[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"paymentType"] intValue] == 3) {
        [dict setObject:@"0" forKey:@"PaymentTypeId"];
        
        NSMutableDictionary* dict11 = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
        NSString* charge = [dict11 valueForKey:@"ElectronicPaymentCharge"];
        double tot = [[grandTotal stringByReplacingOccurrencesOfString:@"£" withString:@""] doubleValue] + [charge doubleValue];
        
        [dict setObject:[NSNumber numberWithDouble:tot] forKey:@"OrderTotal"];
    }
    else {
        [dict setObject:[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"paymentType"] forKey:@"PaymentTypeId"];
        [dict setObject:[grandTotal stringByReplacingOccurrencesOfString:@"£" withString:@""] forKey:@"OrderTotal"];
    }
    
    [dict setObject:kBusinessID forKey:@"BusinessId"];
    if(PayPalData == nil)
        [dict setObject:[NSNull null] forKey:@"PaypalData"];
    else
        [dict setObject:PayPalData forKey:@"PaypalData"];
    
    if(PayPalPayerID == nil)
        [dict setObject:[NSNull null] forKey:@"PaypalPayerId"];
    else
        [dict setObject:PayPalPayerID forKey:@"PaypalPayerId"];
    if(PaypalPaymentId == nil)
        [dict setObject:[NSNull null] forKey:@"PaypalPaymentId"];
    else
        [dict setObject:PaypalPaymentId forKey:@"PaypalPaymentId"];
    if(PayPalSaleID == nil)
        [dict setObject:[NSNull null] forKey:@"PaypalSaleId"];
    else
        [dict setObject:PayPalSaleID forKey:@"PaypalSaleId"];
    if(resultText == nil)
        [dict setObject:[NSNull null] forKey:@"ResponseText"];
    else
        [dict setObject:resultText forKey:@"ResponseText"];
    [dict setObject:scheduleDateTime forKey:@"ScheduledDateTime"];
    
    
    if ([[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"orderType"] intValue] == 2) {
        [dict setObject:@"0" forKey:@"ServiceModelId"];
    }
    else {
        [dict setObject:@"1" forKey:@"ServiceModelId"];
    }
    
    
    
    DataSyncManager* syncMgr = [[DataSyncManager alloc] init];
    syncMgr.serviceKey = kUpdateDatabaseNew;
    syncMgr.delegate = self;
    [syncMgr startPOSTWebServicesWithData:dict];
    
}

#pragma mark - DATASYNCMANGER DELEGATE -

-(void)didFinishServiceWithSuccess:(NSMutableDictionary *)responseData andServiceKey:(NSString *)requestServiceKey {
    
    NSMutableDictionary* responseDict = [[NSMutableDictionary alloc] initWithDictionary:responseData];
    if ([requestServiceKey isEqualToString:kUpdateDatabaseNew]) {
        
        NSLog(@"Response: %@)",responseDict);
        if([[responseDict valueForKey:@"Status"] isEqualToString:@"Success"])
        {
            
            NSString *message = [responseDict valueForKey:@"Message"];
            if(message != (id)[NSNull null])
            {
                if([responseDict valueForKey:@"Message"] != nil && (![[responseDict valueForKey:@"Message"] isEqualToString:@""]))
                {
                    [[SharedContent sharedInstance] setEmailMsg:[responseDict valueForKey:@"Message"]];
                }
            }
            
            [SVProgressHUD dismiss];
            
            [SVProgressHUD showSuccessWithStatus:@"Order placed successfully"];
            
            [self performSegueWithIdentifier:@"showOrderReceiptSegue" sender:nil];
            
        }
        else
        {
            [self didFinishServiceWithFailure:@""];
        }
    }
}

-(void)didFinishServiceWithFailure:(NSString *)errorMsg {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    UIAlertView* alert=[[UIAlertView alloc] initWithTitle:@"Server error"
                                                  message:@"Request timed out, please try again later."
                                                 delegate:self
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles: nil];
    
    if (![errorMsg isEqualToString:@""]) {
        [alert setMessage:errorMsg];
    }
    
//    if([errorMsg isEqualToString:@""])
//    {
//        NSString *msg = @"Your order has been placed.Order number - xxxxx. There was an errorin retrieving your email.Please contact the Restaurant for further queries.Sorry for the inconvenience.";
//        [alert setMessage:msg];
//    }
    
    [alert show];
    
    return;
}

-(NSString *)createOrderXML
{
    
    // allocate serializer
    XMLWriter* xmlWriter = [[XMLWriter alloc]init];
    NSLog(@"cartArr:%@",[[SharedContent sharedInstance] cartArr]);
    NSLog(@"orderDetailsDict:%@",[[SharedContent sharedInstance] orderDetailsDict]);
    
    // start writing XML elements
    NSString *custName = [[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"firstName"] stringByAppendingFormat:@" %@",[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"lastName"]];
    if(custName == nil || [custName isEqualToString:@""])
        custName = @"";
    
    //Ashwani:: Here the pending fields to set are LineDistance, Driving
    NSDateFormatter *formatter;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"ddMMyyyyHHmmss"];
    
    [xmlWriter writeStartElement:@"FinalOrder"];
    [xmlWriter writeAttribute:@"xmlns:xsi" value:@"http://www.w3.org/2001/XMLSchema-instance"];
    [xmlWriter writeAttribute:@"xmlns:xsd" value:@"http://www.w3.org/2001/XMLSchema"];
    
    [xmlWriter writeStartElement:@"Guid"];
    
    // UIDevice *device = [UIDevice currentDevice];
    //NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
    [xmlWriter writeCharacters:[[NSUUID UUID] UUIDString]];
    [xmlWriter writeEndElement];
    
    //Pass here order number value
    [xmlWriter writeStartElement:@"OrderNumber"];
    [xmlWriter writeCharacters:@"0"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"OrderDateTime"];
    [xmlWriter writeCharacters:orderDateTime];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"PaymentType"];
    
    NSString *orderType = [[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"paymentType"] stringValue];
    if(orderType == nil || [orderType isEqualToString:@""])
        orderType = @"";
    
    if([orderType isEqualToString:@"1"]) {
        orderType = @"Cash";
    }
    else if([orderType isEqualToString:@"3"]) {
        orderType = @"Card";
    }
    else {
        orderType = @"Paypal";
    }
    
    
    [xmlWriter writeCharacters:orderType];
    [xmlWriter writeEndElement];
    
    NSString *serviceMode = @"";
    if([[[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"orderType"] stringValue] isEqualToString:@"1"])
        serviceMode = @"Delivery";
    else
        serviceMode = @"Collection";
    [xmlWriter writeStartElement:@"ServiceMode"];
    [xmlWriter writeCharacters:serviceMode];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"ScheduledDateTime"];
    [xmlWriter writeCharacters:scheduleDateTime];
    [xmlWriter writeEndElement];
    
    //instructions
    NSString *notes = [[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"instructions"];
    if(notes != nil && notes.length>0 && (![notes isEqualToString:@""]))
    {
        [xmlWriter writeStartElement:@"Notes"];
        [xmlWriter writeCharacters:notes];
        [xmlWriter writeEndElement];
    }
    
    [xmlWriter writeStartElement:@"CustomerName"];
    [xmlWriter writeCharacters:custName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"CustomerAddress"];
    NSString *address = [[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"address1"];
    if([address length]>0)
        [address stringByAppendingFormat:@",%@",[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"address2"]];
    else
        address = [[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"address2"];
    if(address != nil && address.length>0 && (![address isEqualToString:@""]))
    {
        
        [xmlWriter writeStartElement:@"Line1"];
        [xmlWriter writeCharacters:address];
        [xmlWriter writeEndElement];
    }
    
    NSString *City = [[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"townCity"];
    if(City != nil && City.length>0)
    {
        [xmlWriter writeStartElement:@"City"];
        [xmlWriter writeCharacters:City];
        [xmlWriter writeEndElement];
    }
    
    
    
    NSString *Postcode = [[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"postCode"];
    if(Postcode != nil && Postcode.length>0)
    {
        [xmlWriter writeStartElement:@"Postcode"];
        [xmlWriter writeCharacters:Postcode];
        [xmlWriter writeEndElement];
    }
    
    
    //Ashwani :: Pass here line distance and driving distance
    [xmlWriter writeStartElement:@"LineDistance"];
    [xmlWriter writeCharacters:@"0"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"DrivingDistance"];
    [xmlWriter writeAttribute:@"xsi:nil" value:@"true"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    NSString *phone = [[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"phone"];
    if(phone != nil && phone.length>0)
    {
        [xmlWriter writeStartElement:@"CustomerPhone"];
        [xmlWriter writeCharacters:phone];
        [xmlWriter writeEndElement];
    }
    NSString *email = [[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"email"];
    if(email != nil && email.length>0)
    {
        [xmlWriter writeStartElement:@"CustomerEmail"];
        [xmlWriter writeCharacters:email];
        [xmlWriter writeEndElement];
    }
    
    
    
    //Cart Data
    [xmlWriter writeStartElement:@"CartData"];
    [xmlWriter writeStartElement:@"Items"];
    
    for(int i = 0; i < [[SharedContent sharedInstance] cartArr].count; i++)
    {
        [xmlWriter writeStartElement:@"ItemBase"];
        [xmlWriter writeAttribute:@"xsi:type" value:@"CustomItem"];
        
        [xmlWriter writeStartElement:@"Code"];
        //[xmlWriter writeCharacters:[[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"Code"]];
        [xmlWriter writeCharacters:[[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"Code"]];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"Name"];
        NSString *name = @"";
        NSString *ProdVarName = @"";
        name = [[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"Name"];
        
        //if([[[SharedContent sharedInstance] cartArr] allkeys])
        //if([[[itemArr objectAtIndex:indexPath.row] allKeys] containsObject:@"ProductVariantName"])
        if([[[itemArr objectAtIndex:i] allKeys] containsObject:@"ProductVariantName"])
        {
            ProdVarName = [[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"ProductVariantName"];
        }
        if(name == nil)
        {
            name = @"";
        }
        if(ProdVarName == nil)
        {
            ProdVarName = @"";
        }
        name = [name stringByAppendingFormat:@" (%@)",ProdVarName];
        
        [xmlWriter writeCharacters:name];
        //[xmlWriter writeCharacters:[[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"Name"]];
        [xmlWriter writeEndElement];
        
        //
        [xmlWriter writeStartElement:@"Quantity"];
        [xmlWriter writeCharacters:@"1"];
        [xmlWriter writeEndElement];
        
        //Ashwani :: Set here price for items
        NSString *unitPrice = [[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"OriginalPrice"];
        if(unitPrice == nil || [unitPrice isEqualToString:@""])
        {
            unitPrice = [[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"Price"];
        }
        
        [xmlWriter writeStartElement:@"UnitPrice"];
        if(unitPrice != nil && (![unitPrice isEqualToString:@""]))
        {
            //[xmlWriter writeCharacters:[[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"Price"]];
            [xmlWriter writeCharacters:unitPrice];
        }
        else
            [xmlWriter writeAttribute:@"xsi:nil" value:@"true"];
        [xmlWriter writeEndElement];
        
        //Ashwani :: Add sub items here if any
        NSString *optionCount = [[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:@"ProductComponentsOptionsCount"];
        if([optionCount intValue] > 0)
        {
            
            NSLog(@"Cart Array : %@",[[SharedContent sharedInstance] cartArr]);
            [xmlWriter writeStartElement:@"SubItems"];
            for(int j = 0; j < [optionCount intValue]; j++)
            {
                NSString *itemNo = [@(j) stringValue];
                NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                NSMutableDictionary *dict = [[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:keyName];
                
                
                [xmlWriter writeStartElement:@"ItemBase1"];//26
                [xmlWriter writeAttribute:@"xsi:type" value:@"StandardItem"];
                
                [xmlWriter writeStartElement:@"Code1"];//27
                if([dict valueForKey:@"ProductComponentId"] != nil)
                    [xmlWriter writeCharacters:[[dict valueForKey:@"ProductComponentId"] stringValue]];
                else if([dict valueForKey:@"ProductVariantId"] != nil)
                    [xmlWriter writeCharacters:[[dict valueForKey:@"ProductVariantId"] stringValue]];
                else if([dict valueForKey:@"OptionItemId"] != nil)
                    [xmlWriter writeCharacters:[[dict valueForKey:@"OptionItemId"] stringValue]];
                [xmlWriter writeEndElement];//End 21
                
                [xmlWriter writeStartElement:@"Name1"];//28
                if([dict valueForKey:@"DisplayName"] != nil)
                    [xmlWriter writeCharacters:[dict valueForKey:@"DisplayName"]];
                else if([dict valueForKey:@"Name"] != nil)
                    [xmlWriter writeCharacters:[dict valueForKey:@"Name"]];
                [xmlWriter writeEndElement];//End 22
                
                
                
                //Ashwani :: Set here quantity for multiple items
                int quantity = 0;
                if ([[dict allKeys] containsObject:@"IsOptionsExist"])
                {
                    if ([[dict valueForKey:@"IsOptionsExist"] intValue] == 0)
                        quantity = [[dict valueForKey:@"MaxSelect"] intValue];
                    else
                        quantity = 1;
                }
                else
                    quantity = 1;
                
                NSString *strQuantity = [@(quantity) stringValue];
                
                [xmlWriter writeStartElement:@"Quantity1"];//29
                [xmlWriter writeCharacters:strQuantity];
                [xmlWriter writeEndElement];//End 23
                //
                [xmlWriter writeStartElement:@"UnitPrice1"];//30
                [xmlWriter writeAttribute:@"xsi:nil" value:@"true"];
                //[xmlWriter writeCharacters:@"1"];
                [xmlWriter writeEndElement];//End 24
                
                
                [xmlWriter writeStartElement:@"SubItems1"];//29
                
                //****************START *******************************
                
                
                //Ashwani :: Set here xml for sub to sub items where we will add new items to the xml
                NSString *keyName1 = [@"ProductComponentsSubOptions" stringByAppendingString:itemNo];
                NSMutableArray *arrSubItems = [[[[SharedContent sharedInstance] cartArr] objectAtIndex:i] valueForKey:keyName1];
                for(int k = 0; k < arrSubItems.count; k++)
                {
                    [xmlWriter writeStartElement:@"SubItem"];
                    
                    [xmlWriter writeStartElement:@"Id"];
                    [xmlWriter writeCharacters:[[[arrSubItems objectAtIndex:k] valueForKey:@"OptionItemId"] stringValue]];
                    [xmlWriter writeEndElement];
                    
                    [xmlWriter writeStartElement:@"Name"];
                    [xmlWriter writeCharacters:[[arrSubItems objectAtIndex:k] valueForKey:@"Name"]];
                    [xmlWriter writeEndElement];
                    
                    [xmlWriter writeStartElement:@"Quantity"];
                    [xmlWriter writeCharacters:@"1"];
                    [xmlWriter writeEndElement];
                    //
                    [xmlWriter writeStartElement:@"UnitPrice"];
                    
                    //Ashwani:: Nov 16, 2015 Checking for null values
                    NSString *subItemsPrice = [[arrSubItems objectAtIndex:k] valueForKey:@"Price"];
                    if(subItemsPrice != (id)[NSNull null])
                    {
                        if(subItemsPrice != nil || (![subItemsPrice isEqualToString:@""]))
                            [xmlWriter writeCharacters:[[arrSubItems objectAtIndex:k] valueForKey:@"Price"]];
                        else
                            [xmlWriter writeAttribute:@"xsi:nil" value:@"true"];
                    }
                    else
                        [xmlWriter writeAttribute:@"xsi:nil" value:@"true"];
                    
                    [xmlWriter writeEndElement];
                    
                    [xmlWriter writeEndElement];
                }
                
                
                //*****************END**********************************//
                [xmlWriter writeEndElement];
                [xmlWriter writeEndElement];
                
            }
            //End Sub Items Here
            [xmlWriter writeEndElement];
        }
        [xmlWriter writeEndElement];
    }
    [xmlWriter writeEndElement];
    
    //Ashwani :: Pass here values that required
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    
    [xmlWriter writeStartElement:@"DiscountRate"];
    if([[dict valueForKey:@"DiscountRate"] doubleValue]>0)
        if ([self isDiscountToBeAddedForThreshold:[[dict valueForKey:@"DiscountThreshold"] doubleValue]])
            [xmlWriter writeCharacters:[dict valueForKey:@"DiscountRate"]];
        else
            [xmlWriter writeCharacters:@"0"];
    else
    [xmlWriter writeCharacters:@"0"];
    [xmlWriter writeEndElement];
    
//    [xmlWriter writeStartElement:@"DiscountRate"];
//    [xmlWriter writeCharacters:@"0"];
//    [xmlWriter writeEndElement];
    
    
    
    [xmlWriter writeStartElement:@"ChargableMiles"];
    [xmlWriter writeCharacters:[NSString stringWithFormat:@"%d",(int)[[SharedContent sharedInstance] extraDistanceInMiles]]];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"DeliveryCharge"];
    [xmlWriter writeCharacters:[NSString stringWithFormat:@"%d",(int)[[SharedContent sharedInstance] extraDistanceDeliveryCharge]]];
    [xmlWriter writeEndElement];
    
    //Ashwani :: Epaycharge set by default depends on payment type
    if([[[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"paymentType"] stringValue] isEqualToString:@"1"])
        ePayCharge = @"0";
    else
    {
        NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
        ePayCharge = [dict valueForKey:@"ElectronicPaymentCharge"];
        //ePayCharge = @"0.5";
    }
    [xmlWriter writeStartElement:@"EPayCharge"];
    [xmlWriter writeCharacters:ePayCharge];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeEndElement];
    
    if (![orderType isEqualToString:@"Cash"]) {
        //Pass here paymentid and payerid that required
        [xmlWriter writeStartElement:@"PaymentId"];
        if(PaypalPaymentId == nil)
            [xmlWriter writeCharacters:@"NULL"];
        else
            [xmlWriter writeCharacters:PaypalPaymentId];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"PayerId"];
        [xmlWriter writeCharacters:PayPalPayerID];
        [xmlWriter writeEndElement];
    }
    
    [xmlWriter writeEndElement];
    //[xmlWriter writeEndDocument];
    
    // get the resulting XML string
    NSString* xml = [xmlWriter toString];
    NSLog(@"xml:%@",xml);
    return xml;
}



-(NSString *) randomStringWithLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }
    
    return randomString;
}


- (BOOL) isDiscountToBeAddedForThreshold:(double)threshold {
    
    NSMutableArray* cartArr = [[NSMutableArray alloc] initWithArray:[[SharedContent sharedInstance] cartArr]];
    double total = 0.0;
    
    for (int i = 0; i<cartArr.count; i++) {
        
        total = total + [[[cartArr objectAtIndex:i] valueForKey:@"Price"] doubleValue];
        
    }
    
    if (total>=threshold) {
        return YES;
    }
    
    return NO;
    
}


- (void) stripePaymentSuccess {
    
    resultText = @"NULL";
    isOrderConfirmed = true;
    PayPalData =@"NULL" ;
    PayPalPayerID=[self randomStringWithLength:13] ;
    PaypalPaymentId=[[SharedContent sharedInstance] stripeToken];
    PayPalSaleID=@"NULL";
    clientIP = @"NULL";
    
    [SVProgressHUD showSuccessWithStatus:@"Payment successful"];
    [self updateOrderedDataOnServer];
    
}


- (NSString *) getScheduledDateTimeForPoller {
    
    NSString* retStr;
    int interval;
    
    if ([[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"orderType"] intValue] == 1) {
        
        interval = [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryTime"] intValue];
        
    }
    else {
        
        interval = [[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"CollectionTime"] intValue];
        
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
    NSDate *date = [df dateFromString:[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"requestTime"]];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMinute:-interval]; // note that I'm setting it to -1
    NSDate *finalDate = [gregorian dateByAddingComponents:offsetComponents toDate:date options:0];
    NSLog(@"%@", finalDate);
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"];
    
    retStr = [dateFormatter stringFromDate:finalDate];
    
    return retStr;
    
}

@end
