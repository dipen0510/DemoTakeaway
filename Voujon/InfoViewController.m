//
//  InfoViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    dayArr = [[NSMutableArray alloc] initWithObjects:@"Monday",@"Tuesday",@"Wednesday",@"Thursday",@"Friday",@"Saturday",@"Sunday", nil];
    
    deliveryTimingArr = [[NSMutableArray alloc] init];
    collectionTimingArr = [[NSMutableArray alloc] init];
    
    deliveryTimingArr = [[SharedContent sharedInstance] deliveryTimingArr];
    collectionTimingArr = [[SharedContent sharedInstance] collectionTimingArr];
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    
    
    self.freeWithinValLbl.text = [NSString stringWithFormat:@"%@ Miles",[[dict valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeRadius"]];
    self.chargePerMileValLbl.text = [NSString stringWithFormat:@"£%@",[[dict valueForKey:@"DeliveryPolicy"] valueForKey:@"ChargePerMile"]];
    self.deliveryTimeValLbl.text = [NSString stringWithFormat:@"%@ minutes",[[dict valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryTime"]];
    self.macRadiusValLbl.text = [NSString stringWithFormat:@"%@ Miles",[[dict valueForKey:@"DeliveryPolicy"] valueForKey:@"MaxRadius"]];
    self.collectionTimeValLbl.text = [NSString stringWithFormat:@"%@ minutes",[dict valueForKey:@"CollectionTime"]];
    
    self.lblThreshold.text = [NSString stringWithFormat:@"£%@",[[dict valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"]];
    self.lblFreeDeliveryThreshold.text = [NSString stringWithFormat:@"£%@",[[dict valueForKey:@"DeliveryPolicy"] valueForKey:@"FreeDeliveryThreshold"]];
    
    //Ashwani :: Nov 05, 2015 Add discount offer info here for Get Discount
    float DiscountRate = [[dict valueForKey:@"DiscountRate"] floatValue];
    DiscountRate = DiscountRate*100;
    
    NSString *strDiscount = [NSString stringWithFormat:@" %@%% discount on all orders of £%@ and above for all days excluding Bank Holidays.",[@(DiscountRate) stringValue],[dict valueForKey:@"DiscountThreshold"]];
    //self.DiscountLabel.adjustsFontSizeToFitWidth = YES;
    self.DiscountLabel.text = strDiscount;
    
}



- (void)viewDidLayoutSubviews {
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.infoScrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.infoScrollView.contentSize = CGSizeMake(self.view.frame.size.width - 35.0, contentRect.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:16.0]];
    [label setTextColor:[UIColor whiteColor]];
    
    NSString* string = @"";
    
    if (section == 0) {
        string = @"Collections";
    }
    else {
        string = @"Deliveries";
    }

    /* Section header is in 0th index... */
    [label setText:string];
    [view addSubview:label];
    [view setBackgroundColor:[self.view backgroundColor]]; //your background color...
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"InfoCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
    }
    
    // Configure the cell...
    cell.textLabel.text = [dayArr objectAtIndex:indexPath.row];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.font = [UIFont systemFontOfSize:12.0];
    
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
    
    if (indexPath.section == 0) {
        cell.detailTextLabel.text = [collectionTimingArr objectAtIndex:indexPath.row];
    }
    else {
        cell.detailTextLabel.text = [deliveryTimingArr objectAtIndex:indexPath.row];
    }
    
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

- (IBAction)homeButtonTapped:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
