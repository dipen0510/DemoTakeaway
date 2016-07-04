//
//  OrderReceiptViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 04/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "OrderReceiptViewController.h"

@interface OrderReceiptViewController ()

@end

@implementation OrderReceiptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    itemArr = [[NSMutableArray alloc] init];
    itemArr = [[SharedContent sharedInstance] cartArr];
    
    self.itemTBlView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.itemTBlView.layer.borderWidth = 1.0;
    self.itemTBlView.layer.cornerRadius = 5.0;
    
    [self setupInitalView];

    
    [[SharedContent sharedInstance] setOrderDetailsDict:[[NSMutableDictionary alloc] init]];
    [[SharedContent sharedInstance] setCartArr:[[NSMutableArray alloc] init]];
    [[SharedContent sharedInstance] setExtraDistanceDeliveryCharge:0.0];
    [[SharedContent sharedInstance] setExtraDistanceInMiles:0.0];
    
    if([[SharedContent sharedInstance] emailMsg] != nil && (![[[SharedContent sharedInstance] emailMsg] isEqualToString:@""]))
    {
        UIAlertView* alert=[[UIAlertView alloc] initWithTitle:@"Message"
                                                      message:[[SharedContent sharedInstance] emailMsg]
                                                     delegate:self
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles: nil];
        
        [alert show];
        return;
    }

}

- (void) setupInitalView {
    
    //Ashwani :: Nov 06 send ordertotal
    NSMutableDictionary* dictSettings = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    //Ashwani :: Nov 05, 2015 Add discount offer info here for Get Discount
    float DiscountRate = [[dictSettings valueForKey:@"DiscountRate"] floatValue];
    DiscountRate = DiscountRate*100;
    NSString *DiscountPercentage = [dictSettings valueForKey:@"DiscountRate"];
    NSString *MinimumRateForDiscount = [dictSettings valueForKey:@"DiscountThreshold"];
    
    double calculatedPrice = [[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] doubleValue];
    double minimumAmountForDiscount = [MinimumRateForDiscount doubleValue];
    NSString *grandTotal = @"";
    if([DiscountPercentage floatValue] > 0)
    {
        //Ashwani :: Nov 05, 2015 get here price of discount for
        if(calculatedPrice >= minimumAmountForDiscount)
        {
            double discountPrice = calculatedPrice*[DiscountPercentage doubleValue];
            double totalPrice = calculatedPrice-discountPrice;
            
            grandTotal = [NSString stringWithFormat:@"£%.2f",totalPrice];
        }
    }
    else
        grandTotal = [self getTotalPrice];
    
    //Ashwani :: Nov 17 2015 Check here for ordertype and threshold
    if([[[[[SharedContent sharedInstance] orderDetailsDict] valueForKey:@"orderType"] stringValue] isEqualToString:@"1"])
    {
        if(![self validateFreeDeliveryThreshold])
            grandTotal = [NSString stringWithFormat:@"£%.2f",[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]];
    }
    
    grandTotal = [NSString stringWithFormat:@"£%.2f",([[grandTotal stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] + [[SharedContent sharedInstance] extraDistanceDeliveryCharge])];
    
    self.totalPriceLbl.text = grandTotal;
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    dict = [[SharedContent sharedInstance] orderDetailsDict];
    
    if ([[dict valueForKey:@"instructions"] isEqualToString:@""]) {
        self.specialInstructionsValLbl.text = @"None";
    }
    else {
        self.specialInstructionsValLbl.text = [dict valueForKey:@"instructions"];
    }
    
    if ([[dict valueForKey:@"orderType"] intValue] == 1) {
        
        self.collectionRequestLbl.text = @"Delivery Request";
        
    }
    else {
        
        self.collectionRequestLbl.text = @"Collection Request";
        
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *string = [dateFormatter stringFromDate:[NSDate date]];
    self.orderPlacedAtValLbl.text = string;
    
    //Ashwani :: Apr 11, 2016 Change date Format
    NSLog(@"ORder Request time: %@", [dict valueForKey:@"requestTime"]);
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
    NSDate *date = [df dateFromString:[dict valueForKey:@"requestTime"]];
    
    [df setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    NSString *strDate = [df stringFromDate:date];
    
    self.collectionRequestValLbl.text = [NSString stringWithFormat:@"Your order will be ready at %@",strDate];
    
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
    
    cell.textLabel.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Name"];
    cell.detailTextLabel.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Price"];
    
    return cell;
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)HomeButtonTapped:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}
@end
