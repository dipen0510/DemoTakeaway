//
//  EditOrderViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 22/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "EditOrderViewController.h"
#import "AlertViewController.h"
#import "MZFormSheetController.h"
#import "MZFormSheetSegue.h"
#import "EditOrderCustomTableViewCell.h"

@interface EditOrderViewController ()

@end

@implementation EditOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //Ashwani : Nov 05 2015 initialize discount offer here
    MinimumRateForDiscount = @"";
    DiscountPercentage = @"";
    MoreAmountReqdForDiscount = @"";
    
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    itemArr = [[NSMutableArray alloc] init];
    itemArr = [[SharedContent sharedInstance] cartArr];
    [self prepareArrayForDesctiptioncontent];
    
    //self.totalPriceValLbl.text = [self getTotalPrice];
    
    self.orderTblView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.orderTblView.layer.borderWidth = 1.0;
    self.orderTblView.layer.cornerRadius = 5.0;
    self.orderTblView.tableFooterView = [UIView new];
    
    [self updatePriceAfterSelection];
    
    
}

- (void) prepareArrayForDesctiptioncontent {
    
    descriptionArr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<itemArr.count; i++) {
        
        if ([[[itemArr objectAtIndex:i] allKeys] containsObject:@"ProductComponentsOptionsCount"]) {
            if ([[[itemArr objectAtIndex:i] valueForKey:@"ProductComponentsOptionsCount"] intValue] > 0) {
                
                NSString* str = @"";
                
                for (int j = 0; j< [[[itemArr objectAtIndex:i] valueForKey:@"ProductComponentsOptionsCount"] intValue]; j++) {
                    
                    if (j!=0) {
                        str = [NSString stringWithFormat:@"%@, ",str];
                    }
                    
                    if ([[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"DisplayName"]) {
                        
                        
                        //Ashwani :: Check here if item has min select more than 0 then add name with that
                        NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                        tempDict = [[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]];
                        if ([[tempDict allKeys] containsObject:@"IsOptionsExist"]) {
                            if ([[tempDict valueForKey:@"IsOptionsExist"] intValue] == 0)
                            {
                                int minSelect = [[tempDict valueForKey:@"MaxSelect"] intValue];
                                NSString *opt = [[@(minSelect) stringValue] stringByAppendingString:@" X "];
                                opt = [opt stringByAppendingFormat:@"%@",[[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"DisplayName"]];
                                str = [NSString stringWithFormat:@"%@%@",str,opt];
                                
                                //str = [];
                            }
                        }
                        else
                        {
                            int minSelect = 1;//[[tempDict valueForKey:@"MaxSelect"] intValue];
                            NSString *opt = [[@(minSelect) stringValue] stringByAppendingString:@" X "];
                            opt = [opt stringByAppendingFormat:@"%@",[[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"DisplayName"]];
                            str = [NSString stringWithFormat:@"%@%@",str,opt];
                            
                            //str = [NSString stringWithFormat:@"%@%@",str,[[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"DisplayName"]];
                        }
                        
                        
                        
                        //Ashwani :: Set here items according to format
                        //***********************  START *******************************//
                        NSMutableArray *arr = [[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsSubOptions%d",j]];
                        if(arr.count > 0)
                        {
                            for(int k = 0; k < arr.count; k++)
                            {
                                NSString *name = @"";
                                name = [[arr objectAtIndex:k ] valueForKey:@"Name"];
                                if([[arr objectAtIndex:k ] valueForKey:@"Price"] != (id)[NSNull null] )
                                    name = [name stringByAppendingFormat:@" For £%@",[[arr objectAtIndex:k ] valueForKey:@"Price"]];
                                
                                //str = [NSString stringWithFormat:@"%@,    %@",str,[[arr objectAtIndex:k ] valueForKey:@"Name"]];
                                
                                str = [NSString stringWithFormat:@"%@,    %@",str,name];
                            }
                        }
                        //(**********************  END *********************************//
                    }
                    else {
                        str = [NSString stringWithFormat:@"%@%@",str,[[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"Name"]];
                        
                        if([[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"Price"] != (id)[NSNull null] && [[[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"Price"] floatValue] > 0.00)
                        {
                            
                            str = [str stringByAppendingFormat:@" (£%@)", [[[itemArr objectAtIndex:i] valueForKey:[NSString stringWithFormat:@"ProductComponentsOptions%d",j]] valueForKey:@"Price"]];
                        }
                        
                        
                    }
                   
                }
                [descriptionArr addObject:str];
                
            }
            else {
                [descriptionArr addObject: @""];
            }
        }
        else {
            [descriptionArr addObject: @""];
        }
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TABLEVIEW DELEGATES

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [itemArr count];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Ashwani :: Use custom table for set subitems one below another
     static NSString *simpleTableIdentifier = @"SimpleTableItem";
     
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
     cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
     cell.backgroundColor = [UIColor clearColor];
     cell.accessoryType = UITableViewCellAccessoryNone;
     cell.layer.shouldRasterize = YES;
     cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    int y = 5;
    UILabel *lblItemName = [[UILabel alloc] initWithFrame:CGRectMake(10, y, cell.frame.size.width-100, 20)];
    lblItemName.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Name"];
    [lblItemName setFont:[UIFont systemFontOfSize:13.0]];
    lblItemName.adjustsFontSizeToFitWidth = YES;
    lblItemName.numberOfLines = 2;
    [cell addSubview:lblItemName];
    
    //Ashwani :: March 02 2016 Changes Made to show data in correct format
    if([[[itemArr objectAtIndex:indexPath.row] allKeys] containsObject:@"ProductVariantName"])
    {
        lblItemName.text = [[[itemArr objectAtIndex:indexPath.row] valueForKey:@"Name"] stringByAppendingFormat:@" (%@)",[[itemArr objectAtIndex:indexPath.row] valueForKey:@"ProductVariantName"]];
    }
    
    UILabel *lblPrice = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width-80, y, 80, 20)];
    lblPrice.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Price"];
    [lblPrice setFont:[UIFont systemFontOfSize:13.0]];
    lblPrice.adjustsFontSizeToFitWidth = YES;
    [cell addSubview:lblPrice];
    
    y+=lblItemName.frame.size.height;
    UILabel *lblDescription = [[UILabel alloc] initWithFrame:CGRectMake(10, y, cell.frame.size.width-100, 20)];
    lblDescription.text = [[itemArr objectAtIndex:indexPath.row] valueForKey:@"Name"];
    [lblDescription setFont:[UIFont systemFontOfSize:12.0]];
    lblDescription.adjustsFontSizeToFitWidth = YES;
    [cell addSubview:lblDescription];
    
    
    NSString *descriptionItem = [descriptionArr objectAtIndex:indexPath.row];
    NSArray *items;
    if([descriptionItem length] != 0)
    {
        descriptionItem = [descriptionItem stringByReplacingOccurrencesOfString:@"," withString:@"\n"];
        //NSLog(@"Items are:  %@",descriptionItem);
        items = [descriptionItem componentsSeparatedByString:@"\n"];
        lblDescription.text = descriptionItem;
        //NSLog(@"Items are:  %@",descriptionItem);
        
        lblDescription.numberOfLines = [items count];
        CGFloat lblHeight = [items count]*20;
        lblDescription.frame = CGRectMake(10, y, cell.frame.size.width-100, lblHeight);
    }
    else
        lblDescription.text = [descriptionArr objectAtIndex:indexPath.row];
    
    return cell;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    
    NSString *descriptionItem = [descriptionArr objectAtIndex:indexPath.row];
    NSArray *items;
    if([descriptionItem length] != 0)
    {
        descriptionItem = [descriptionItem stringByReplacingOccurrencesOfString:@"," withString:@"\n"];
        //NSLog(@"Items are:  %@",descriptionItem);
        items = [descriptionItem componentsSeparatedByString:@"\n"];
        
        return (([items count])+2)*20;
    }
    else
        return 65.0;
    
}


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"deleting row %ld",(long)indexPath.row);
        
        [itemArr removeObjectAtIndex:indexPath.row];
        [[SharedContent sharedInstance] setCartArr:itemArr];
        //self.totalPriceValLbl.text = [self getTotalPrice];
        
        //Ashwani :: Update price value here
        [self updatePriceAfterSelection];
        
        //************END****************//
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        if ([itemArr count]==0) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    } else {
        NSLog(@"Unhandled editing style! ");
    }
}


//Ashwani :: This function will be use to get updated price after discount
-(void)updatePriceAfterSelection
{
    //Ashwani :: Nov 05, get Discount Items cost here from settings
    
    //NSLog(@"cartArr:%@",[[SharedContent sharedInstance] cartArr]);
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    //Ashwani :: Nov 05, 2015 Add discount offer info here for Get Discount
    DiscountPercentage = [dict valueForKey:@"DiscountRate"];
    MinimumRateForDiscount = [dict valueForKey:@"DiscountThreshold"];
    
    
    double calculatedPrice = [[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] doubleValue];
    double minimumAmountForDiscount = [MinimumRateForDiscount doubleValue];
    if([DiscountPercentage floatValue] > 0)
    {
        //Ashwani :: Nov 05, 2015 get here price of discount for
        if(calculatedPrice >= minimumAmountForDiscount)
        {
            double discountPrice = calculatedPrice*[DiscountPercentage doubleValue];
            double totalPrice = calculatedPrice-discountPrice;
            
            self.DiscountofferInfoLabel.hidden  = TRUE;
            self.SubTotalPriceValLbl.text = [NSString stringWithFormat:@"£%.2f",calculatedPrice];
            self.DiscountValLbl.text = [NSString stringWithFormat:@"£%.2f",discountPrice];
            self.totalPriceValLbl.text = [NSString stringWithFormat:@"£%.2f",totalPrice];
        }
        else
        {
            float moreAmountRequired = minimumAmountForDiscount-calculatedPrice;
            MoreAmountReqdForDiscount = [NSString stringWithFormat:@"£%.2f",moreAmountRequired];
            
            self.SubTotalPriceValLbl.text = [self getTotalPrice];
            self.DiscountValLbl.text = @"£0.0";
            self.totalPriceValLbl.text = [self getTotalPrice];
            
            double disPercentage = [DiscountPercentage doubleValue]*100;
            NSString *discountMsg = [NSString stringWithFormat:@"%@ more to get %.2f%% discount.",MoreAmountReqdForDiscount,disPercentage];
            
            //self.DiscountofferInfoLabel.textAlignment = NSTextAlignmentJustified;
            self.DiscountofferInfoLabel.text = discountMsg;
            
        }
    }
    else
    {
        self.DiscountofferInfoLabel.hidden  = TRUE;
        self.SubTotalPriceValLbl.text = [self getTotalPrice];
        self.DiscountValLbl.text = @"0.0";
        self.totalPriceValLbl.text = [self getTotalPrice];
    }
}
//*********************END***************************//
- (NSString *) getTotalPrice {
    
    double price = 0.0;
    
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    tmpArr  = [itemArr valueForKey:@"Price"];
    
    for (int i = 0; i < tmpArr.count; i++) {
        
        price = price + [[tmpArr objectAtIndex:i] doubleValue];
        
    }
    
    return [NSString stringWithFormat:@"£%.2f",price];
    
}

- (BOOL) validateMinimumOrderAmount {
    
    if ([[self.totalPriceValLbl.text stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] < [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"] floatValue]) {
        
        return false;
    }
    return true;
}

- (BOOL) validateFreeDeliveryThreshold {
    
    if ([[self.totalPriceValLbl.text stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] < [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]) {
        
        return false;
    }
    return true;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([[segue identifier] isEqualToString:@"orderTimeAlertSegue"]) {
        
        AlertViewController* controller = (AlertViewController *)[segue destinationViewController];
        
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
            //didTapBackGroundView = true;
        };
        
        formSheet.shadowRadius = 2.0;
        formSheet.shadowOpacity = 0.3;
        formSheet.shouldDismissOnBackgroundViewTap = YES;
        formSheet.shouldCenterVertically = YES;
        formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
            
        };
        
    }
    
}

- (IBAction)addItemsButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)nextButtonTapped:(id)sender {
    
     //if ([self validateMinimumOrderAmount])
    //{
        //if([self validateFreeDeliveryThreshold])
            [self performSegueWithIdentifier:@"showOrderDetailsSegue" sender:nil];
//        else
//        {
//            NSString *amount = [NSString stringWithFormat:@"%.2f",[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]];
//            double calculatedPrice = [[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] doubleValue];
//            int moreAmount = [amount doubleValue] - calculatedPrice;
//            
//            NSString *msg = [NSString stringWithFormat:@"Please add items worth £%@ or more into the cart for Free Delivery or your total will be automatically rounded off to £%@", [@(moreAmount) stringValue],amount];
//            
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:msg delegate:self cancelButtonTitle:@"Round off" otherButtonTitles: @"Add Item", nil];
//            [alert show];
//            alert.tag = 100;
//            return;
//        }
    
//    }
//    else {
//        
//        NSString *amount = [NSString stringWithFormat:@"%.2f",[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"] floatValue]];
//        NSString *msg = [@"Add more items, Minimum amount for delivery is " stringByAppendingFormat:@"£%@", amount];
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
//        [alert show];
//        return;
//
//        
//    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    //if(delegate.)
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    //if(delegate.)
}

#pragma mark - Alert View Delegate - 
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100)
    {
        if(buttonIndex == 0)
        {
            self.totalPriceValLbl.text = [NSString stringWithFormat:@"£%.2f",[[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"] floatValue]];
            
            [self performSegueWithIdentifier:@"showOrderDetailsSegue" sender:nil];
        }
    }
}

@end
