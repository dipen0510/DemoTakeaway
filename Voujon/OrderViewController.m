//
//  OrderViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "OrderViewController.h"
#import "LMDropdownView.h"
#import "LMMenuCell.h"
#import "MZFormSheetController.h"
#import "MZFormSheetSegue.h"

@interface OrderViewController ()<UITableViewDataSource, UITableViewDelegate, LMDropdownViewDelegate,MZFormSheetBackgroundWindowDelegate>

@property (assign, nonatomic) NSInteger currentMapTypeIndex;

@property (strong, nonatomic) IBOutlet UITableView *menuTableView;

@property (strong, nonatomic) LMDropdownView *dropdownView;

@end

@implementation OrderViewController

int txtTag = -1;
int toppingTag = -1;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    categoryArr = [[NSMutableArray alloc] init];
    expandedIndexPath = [[NSIndexPath alloc] init];
    menuDisplayArr = [[NSMutableArray alloc] init];
    selectedPickerContent = [[NSMutableDictionary alloc] init];
    strengthArr = [[NSMutableArray alloc] init];
    //Ashwani :: Sept 04
    componentItemArr = [[NSMutableArray alloc] init];
    selectedComponentPickerContent = [[NSMutableArray alloc] init];
    
    //Ashwani sept 07 :: Initialize option arr
    prodOptionsArr = [[NSMutableArray alloc] init];
    prodOptionsItemArr = [[NSMutableArray alloc] init];
    
    self.currentMapTypeIndex = 0;
    [self getOrderMenuData];
    
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 126, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-126)];
    view.backgroundColor = [UIColor greenColor];
    view.hidden = TRUE;
    
    [self refreshFinalOrder];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [self refreshFinalOrder];
}

-(void)viewDidAppear:(BOOL)animated {
    [[MZFormSheetBackgroundWindow appearance] setBackgroundBlurEffect:YES];
    [[MZFormSheetBackgroundWindow appearance] setBlurRadius:5.0];
    [[MZFormSheetBackgroundWindow appearance] setBackgroundColor:[UIColor clearColor]];
}

- (BOOL) validateOrderTimings {
    
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
    
    
    NSLog(@"%@",[[SharedContent sharedInstance] deliveryTimingArr]);
    
    
    NSString* str = [[[SharedContent sharedInstance] deliveryTimingArr] objectAtIndex:currentWeekDay];
    
    long fromHour = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] firstObject] intValue];
    long fromMinute = [[[[[str componentsSeparatedByString:@" - "] firstObject] componentsSeparatedByString:@":"] lastObject] intValue];
    long toHour = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] firstObject] intValue];
    long toMinute = [[[[[str componentsSeparatedByString:@" - "] lastObject] componentsSeparatedByString:@":"] lastObject] intValue];
    
    long currentTime = (currentHour * 100) + currentMinute;
    long fromTime = (fromHour * 100) + fromMinute;
    long toTime = (toHour * 100) + toMinute;
    
    if (toTime < fromTime) {
        
        toTime = toTime + 2400;
        
    }
    
    if (currentTime >= 0 && currentTime <= 1300) {
        currentTime = currentTime + 1200;
        
        
    }
    
    if (((currentTime > fromTime) && (currentTime < toTime))) {
        [[SharedContent sharedInstance] setIsRestoOpen:YES];
        return true;
    }
    
    [[SharedContent sharedInstance] setIsRestoOpen:NO];
    return false;
    
}

-(void) getOrderMenuData {
    
    [SVProgressHUD showWithStatus:@""];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:kBusinessID forKey:@"BusinessId"];
    
    DataSyncManager* syncMgr = [[DataSyncManager alloc] init];
    syncMgr.serviceKey = kGetAllProductsNew;
    syncMgr.delegate = self;
    [syncMgr startPOSTWebServicesWithData:dict];
}

-(void) getCustomProductData {
    
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:kBusinessID forKey:@"BusinessId"];
    
    DataSyncManager* syncMgr = [[DataSyncManager alloc] init];
    syncMgr.serviceKey = kGetCustomProductsNew;
    syncMgr.delegate = self;
    [syncMgr startPOSTWebServicesWithData:dict];
    
}

-(void) getComponentItems{

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:kBusinessID forKey:@"BusinessId"];
    
    DataSyncManager* syncMgr = [[DataSyncManager alloc] init];
    syncMgr.serviceKey = kGetComponentItemsNew;
    syncMgr.delegate = self;
    [syncMgr startPOSTWebServicesWithData:dict];
}

-(void) getOptions{
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:kBusinessID forKey:@"BusinessId"];
    
    DataSyncManager* syncMgr = [[DataSyncManager alloc] init];
    syncMgr.serviceKey = kGetOptionsNew;
    syncMgr.delegate = self;
    [syncMgr startPOSTWebServicesWithData:dict];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - DATASYNCMANGER DELEGATE

-(void)didFinishServiceWithSuccess:(NSMutableDictionary *)responseData andServiceKey:(NSString *)requestServiceKey {
    
    NSMutableDictionary* responseDict = [[NSMutableDictionary alloc] initWithDictionary:responseData];
    
    if ([requestServiceKey isEqualToString:kGetAllProductsNew]) {
        categoryArr = [[NSMutableArray alloc] init];
        categoryArr = [[responseDict valueForKey:@"Items"] mutableCopy];
        
        menuDisplayArr = [[NSMutableArray alloc] init];
        for(int i = 0; i < categoryArr.count; i++)
        {
            [menuDisplayArr addObject:[categoryArr objectAtIndex:i]];
        }
        [self getCustomProductData];
        
    }
    
    if ([requestServiceKey isEqualToString:kGetCustomProductsNew]) {
        
        //Ashwani :: Sept 04 2015 Get Custom Data
        NSMutableArray *customItems = [[NSMutableArray alloc] init];
        if([responseDict valueForKey:@"CustomItems"] != (id)[NSNull null])
        {
            customItems = [[responseDict valueForKey:@"CustomItems"] mutableCopy];
            if(customItems != nil)
            {
                NSMutableArray *arr = [customItems valueForKey:@"CustomProducts"];
                if(arr && ![arr isEqual:[NSNull null]] && [arr count] > 0)
                {
                    for(int i = 0; i < categoryArr.count; i++)
                    {
                        [customItems addObject:[categoryArr objectAtIndex:i]];
                    }
                    menuDisplayArr = [[NSMutableArray alloc] init];
                    categoryArr = [[NSMutableArray alloc] init];
                    for(int i = 0; i < customItems.count; i++)
                    {
                        [menuDisplayArr addObject:[customItems objectAtIndex:i]];
                        [categoryArr addObject:[customItems objectAtIndex:i]];
                    }
                }
                
            }
        }
        
        [self.menuTableView setFrame:CGRectMake(0,0,CGRectGetWidth(self.view.bounds),MIN(CGRectGetHeight(self.view.bounds)/2, categoryArr.count * 50) + 18)];
        [self getComponentItems];
    }
    if ([requestServiceKey isEqualToString:kGetComponentItemsNew]) {
        //NSLog(@"Response: %@)",responseDict);
        NSMutableArray *componentItems = [[NSMutableArray alloc] init];
        componentItems = [[responseDict valueForKey:@"Components"] mutableCopy];
        for(int i = 0; i < componentItems.count; i++)
        {
            [componentItemArr addObject:[componentItems objectAtIndex:i]];
        }
        [self getOptions];
    }
    
    if ([requestServiceKey isEqualToString:kGetOptionsNew]) {
    
        //Ashwnai :: reload table after getting all records
        [SVProgressHUD dismiss];
        [SVProgressHUD showSuccessWithStatus:@"Data downloaded successfully"];
        
        //NSLog(@"%@ : ",responseDict);
        prodOptionsArr = [[responseDict valueForKey:@"ProductOptions"] mutableCopy];
        prodOptionsItemArr = [[responseDict valueForKey:@"ProductOptionsItem"] mutableCopy];
        
        [self.menuTableView reloadData];
        [self.orderMenuTblView reloadData];
        if (![self validateOrderTimings]) {
            [self performSegueWithIdentifier:@"orderTimeAlertSegue" sender:nil];
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
    
    [alert show];
    
    return;
}

#pragma mark - DROPDOWN VIEW
- (void)showDropDownView
{
    // Init dropdown view
    if (!self.dropdownView) {
        self.dropdownView = [LMDropdownView dropdownView];
        self.dropdownView.delegate = self;
        
        // Customize Dropdown style
        self.dropdownView.closedScale = 0.85;
        self.dropdownView.blurRadius = 5;
        self.dropdownView.blackMaskAlpha = 0.5;
        self.dropdownView.animationDuration = 0.5;
        self.dropdownView.animationBounceHeight = 20;
        self.dropdownView.contentBackgroundColor = [UIColor lightGrayColor];
    }
    
    // Show/hide dropdown view
    if ([self.dropdownView isOpen]) {
        [self.dropdownView hide];
    }
    else {
        //[self.dropdownView showFromNavigationController:self.navigationController withContentView:self.menuTableView];
        [self.dropdownView showInView:self.orderMenuTblView withContentView:self.menuTableView atOrigin:CGPointMake(0, 0)];
    }
}

- (void)dropdownViewWillShow:(LMDropdownView *)dropdownView
{
    NSLog(@"Dropdown view will show");
}

- (void)dropdownViewDidShow:(LMDropdownView *)dropdownView
{
    NSLog(@"Dropdown view did show");
}

- (void)dropdownViewWillHide:(LMDropdownView *)dropdownView
{
    NSLog(@"Dropdown view will hide");
}

- (void)dropdownViewDidHide:(LMDropdownView *)dropdownView
{
    NSLog(@"Dropdown view did hide");
    
}


#pragma mark - Picker Done Tapped -
-(void)DoneButtonTapped:(id)sender
{
    [picker1 removeFromSuperview];
    [componentPickerDoneButton removeFromSuperview];
}

-(void)DoneButtonTappedCustom:(id)sender
{
    //Ashwani :: Nov 16,2015 Check here for minimum selection of items if exist
    if(selVariants.count < minselect)
    {
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Message"
                                                     message:[@"Select at least " stringByAppendingFormat:@"%d items",minselect]
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil, nil];
            [al show];
            return;
    }
    
    //Ashwani :: Oct 30, 2015 set user interaction Enable for orderMenuTblView
    self.orderMenuTblView.userInteractionEnabled = TRUE;
    [selOfferVariants addObjectsFromArray:selVariants];
    
    NSString * str = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"DisplayName"];
    //Ashwani :: Here add product component options to main array
    if(selVariants.count>0)
    {
        NSMutableDictionary *dicTemp = [selectedComponentPickerContent objectAtIndex:SelOfferIndex];
        [dicTemp setObject:selVariants forKey:@"ProductComponents"];
        [selectedComponentPickerContent replaceObjectAtIndex:SelOfferIndex withObject:dicTemp];
        
        str = @"";
        for(int i = 0; i < selVariants.count; i++)
        {
            if([str isEqualToString:@""] || str == nil)
                str = [[selVariants objectAtIndex:i] valueForKey:@"DisplayName"];
            else
                str = [str stringByAppendingFormat:@" & %@",[[selVariants objectAtIndex:i] valueForKey:@"DisplayName"]];
        }
    }
    else
    {
        if([[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] allKeys] containsObject:@"ProductComponents"])
        {
            NSMutableDictionary *dicTemp = [selectedComponentPickerContent objectAtIndex:SelOfferIndex];
            [dicTemp removeObjectForKey:@"ProductComponents"];
            [selectedComponentPickerContent replaceObjectAtIndex:SelOfferIndex withObject:dicTemp];
        }
    }
    [viewHeader removeFromSuperview];
    
    //Ashwani :: Oct 30 2015 //set price here for item
    float StandardOfferPrice = 0.0f;
    NSString *strStandardOfferPrice;
    NSString *offerPrice = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"offerPrice"];
    if([offerPrice isEqualToString:@"0.00"])
    {
        StandardOfferPrice = 0.0f;
        for(int i = 0; i < [selectedComponentPickerContent count]; i++)
        {
            BOOL isOption = [[[selectedComponentPickerContent objectAtIndex:i] valueForKey:@"IsOptionsExist"] boolValue];
            if(isOption)
            {
                NSMutableArray *arrCOmp = [[selectedComponentPickerContent objectAtIndex:i] valueForKey:@"ProductComponents"];
                for(int j = 0; j < arrCOmp.count; j++)
                {
                    NSString *price = [[arrCOmp objectAtIndex:j] valueForKey:@"Price"];
                    
                    if(price != (id)[NSNull null])
                    {
                        StandardOfferPrice = StandardOfferPrice+[price floatValue];
                        //Ashwani :: Add price for other item here if exist
                        //strStandardOfferPrice = [NSString stringWithFormat:@"£%.02f",StandardOfferPrice];
                    }
                }
            }
        }
    }
    else
    {
        StandardOfferPrice = [offerPrice floatValue];
        
    }
    
    /*--------------- END --------------------------*/
    
    ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
    cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
    
    UIButton *btn = (UIButton *)[cell viewWithTag:txtTag];
    if((![str isEqualToString:@""])){
        [btn setTitle:str forState:UIControlStateNormal];
        
        if([str length] >50)
            [btn.titleLabel setFont:[UIFont systemFontOfSize:10]];
    }
    
    [viewHeader removeFromSuperview];
    if(selOfferToppings.count>0)
    {
        //NSMutableArray *arrKeys = (NSMutableArray *)[compToppings allKeys];
       // for(int  i = 0; i < arrKeys.count; i++)
       // {
            NSMutableArray *arrObj = selOfferToppings;
            NSLog(@"arrObj %@", arrObj);
            for(int j = 0; j < arrObj.count; j++)
            {
                NSMutableArray *arrKey2 = (NSMutableArray *)[[arrObj objectAtIndex:j] allKeys];
                //if(arrKey2 containsObject:<#(nonnull id)#>)
                for(int k = 0; k < arrKey2.count; k++)
                {
                    if([[arrKey2 objectAtIndex:k] containsString:@"ProductOptTopping"])
                    {
                        NSMutableArray *arrObj2 = [[arrObj objectAtIndex:j] valueForKey:[arrKey2 objectAtIndex:k]];
                        for(int l = 0; l < arrObj2.count; l++)
                        {
                            NSString *price = [[arrObj2 objectAtIndex:l] valueForKey:@"Price"];
                            if(price != (id)[NSNull null])
                                StandardOfferPrice = StandardOfferPrice+[price floatValue];
                        }
                        
                    }
                }
            }
        //}
    }
    strStandardOfferPrice = [NSString stringWithFormat:@"£%.02f",StandardOfferPrice];
    if(strStandardOfferPrice != nil && (![strStandardOfferPrice isEqualToString:@""]))
        cell.optionsPriceLbl.text = strStandardOfferPrice;
    if(selVariants.count > 0)
    {
        for(int i = 0; i < [selVariants count]; i++)
        {
           NSMutableArray *arrProductVarOptions = [[selVariants objectAtIndex:i] valueForKey:@"LstProductVariantOptions"];
            if(arrProductVarOptions.count>0)
            {
                NSString *itemSelect = [[arrProductVarOptions objectAtIndex:0]valueForKey:@"VariantMaxSelect"];
                if(itemSelect != (id)[NSNull null])
                {
                    int maxItemSelect = [[[arrProductVarOptions objectAtIndex:0]valueForKey:@"VariantMaxSelect"] intValue];
                    if(selVariants.count > 0 && maxItemSelect>0)
                    {
                        [self createToppingViewForOffers];
                        break;
                    }
                }
            }
        }
    }
    
    return;
    ////---------------  END ------------------
}

#pragma mark - Topping View For Offers -
-(void)createToppingViewForOffers
{
    SelVariantIndex = -1;
    DeviceHeight = [UIScreen mainScreen].bounds.size.height;
    DeviceWidth = [UIScreen mainScreen].bounds.size.width;
    
    offerDict = [[NSMutableDictionary alloc] init];
    
    //AK :: create view using for reject appointment and assign appointment later when
    // user go to reject or assign the appointment later
    customView1 = [[UIView alloc] initWithFrame: CGRectMake ( 0, 0, DeviceWidth, DeviceHeight)];
    customView1.backgroundColor = [UIColor blackColor];
    customView1.alpha = 0.5;
    [[[UIApplication sharedApplication] keyWindow] addSubview:customView1];
    
    customView2 = [[UIView alloc] initWithFrame: CGRectMake ( 10, 40, customView1.frame.size.width-20, customView1.frame.size.height-80)];
    customView2.backgroundColor = [UIColor whiteColor];
    customView2.layer.cornerRadius = 4.0;
    customView2.layer.borderWidth = 0.5;
    //customView1.
    customView2.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [[[UIApplication sharedApplication] keyWindow] addSubview:customView2];
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, customView2.frame.size.width, customView2.frame.size.height)];
    scrollView.scrollEnabled = TRUE;
    scrollView.backgroundColor = [UIColor whiteColor];
    [customView2 addSubview:scrollView];
    
    UIView *vHeader = [[UIView alloc] initWithFrame: CGRectMake (0, 0, customView2.frame.size.width, 40)];
    vHeader.backgroundColor = [UIColor colorWithRed:70/255.0f green:156/255.0f blue:158/255.0f alpha:1.0f];
    vHeader.layer.cornerRadius = 0.0;
    vHeader.layer.borderWidth = 0.5;
    vHeader.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [scrollView addSubview:vHeader];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, vHeader.frame.size.width, 20)];
    lbl.text = @"Add Toppings";
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:14.0f];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.backgroundColor = [UIColor clearColor];
    [vHeader addSubview:lbl];
    
    int y = 10;
    
    y+=vHeader.frame.size.height+10;
    for(int i = 0; i < selVariants.count; i++)
    {
        UILabel *lblToppName = [[UILabel alloc] initWithFrame:CGRectMake(10, y, scrollView.frame.size.width-20, 20)];
        lblToppName.text = [[selVariants objectAtIndex:i] valueForKey:@"DisplayName"];
        lblToppName.textColor = [UIColor blackColor];
        lblToppName.font = [UIFont boldSystemFontOfSize:12.0f];
        lblToppName.textAlignment = NSTextAlignmentCenter;
        lblToppName.backgroundColor = [UIColor clearColor];
        lblToppName.adjustsFontSizeToFitWidth = YES;
        [scrollView addSubview:lblToppName];
        
        y+=lblToppName.frame.size.height+10;
        NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
        arrDict = [selVariants objectAtIndex:i];
        NSMutableArray *arrProductVarOptions = [arrDict valueForKey:@"LstProductVariantOptions"];
        for(int j = 0; j < arrProductVarOptions.count; j++)
        {
            NSString *itemSelect = [[arrProductVarOptions objectAtIndex:j] valueForKey:@"VariantMaxSelect"];
            if(itemSelect != (id)[NSNull null])
            {
                UILabel *lblToppName = [[UILabel alloc] initWithFrame:CGRectMake(10, y, scrollView.frame.size.width-20, 20)];
                lblToppName.text = [[arrProductVarOptions objectAtIndex:j ]  valueForKey:@"VariantOption"];
                lblToppName.textColor = [UIColor blackColor];
                lblToppName.font = [UIFont systemFontOfSize:12.0f];
                lblToppName.textAlignment = NSTextAlignmentLeft;
                lblToppName.backgroundColor = [UIColor clearColor];
                lblToppName.adjustsFontSizeToFitWidth = YES;
                [scrollView addSubview:lblToppName];
                
                y+=lblToppName.frame.size.height+5;
                
                UIButton *productOptButton = [UIButton buttonWithType:UIButtonTypeCustom];
                productOptButton.frame = CGRectMake(10, y, scrollView.frame.size.width-20, 30);
                productOptButton.showsTouchWhenHighlighted = YES;
                [productOptButton setBackgroundColor:[UIColor  clearColor]];
                
                switch (i) {
                    case 0:
                        productOptButton.tag = j+1000;
                        break;
                        
                    case 1:
                        productOptButton.tag = j+2000;
                        break;
                        
                    case 2:
                        productOptButton.tag = j+3000;
                        break;
                        
                    case 3:
                        productOptButton.tag = j+4000;
                        break;
                    case 4:
                        productOptButton.tag = j+5000;
                        break;
                        
                    default:
                        break;
                }
                
                
                [productOptButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                productOptButton.layer.cornerRadius = 4.0f;
                productOptButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                productOptButton.layer.borderWidth = 0.3;
                productOptButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
                [productOptButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
                productOptButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
                
                //Ashwani ":: set the selected text on button from heer
                [productOptButton setTitle:@"Please select toppings" forState:UIControlStateNormal];
                
                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(productOptButton.frame.size.width-30, 0, 30, 30)];
                imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
                [productOptButton addSubview:imgView];
                [productOptButton addTarget:self action:@selector(createTblToppingPicker:) forControlEvents:UIControlEventTouchUpInside];
                [scrollView addSubview:productOptButton];
                
                y+=productOptButton.frame.size.height+20;
                
                
            }
        }
        
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, y, scrollView.frame.size.width, 1)];
        separator.backgroundColor = [UIColor blackColor];
        [scrollView addSubview:separator];
        
        y+=separator.frame.size.height+30;
    }
    
    
    y+=20;
    
    UIButton *DoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    DoneButton.frame = CGRectMake(20, y, (scrollView.frame.size.width-60)/2, 40);
    DoneButton.showsTouchWhenHighlighted = YES;
    [DoneButton setBackgroundColor:[UIColor colorWithRed:70/255.0f green:156/255.0f blue:158/255.0f alpha:1.0f]];
    [DoneButton setTitle:@"Add" forState:UIControlStateNormal];
    [DoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    DoneButton.layer.cornerRadius = 4.0f;
    DoneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    DoneButton.layer.borderWidth = 0.3;
    DoneButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [DoneButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
    DoneButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [DoneButton addTarget:self action:@selector(SaveToppingsTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [scrollView addSubview:DoneButton];
    
    UIButton *CancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CancelButton.frame = CGRectMake(DoneButton.frame.size.width+40, y, (scrollView.frame.size.width-60)/2, 40);
    CancelButton.showsTouchWhenHighlighted = YES;
    [CancelButton setBackgroundColor:[UIColor redColor]];
    [CancelButton setTitle:@"Skip" forState:UIControlStateNormal];
    [CancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    CancelButton.layer.cornerRadius = 4.0f;
    CancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    CancelButton.layer.borderWidth = 0.3;
    CancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [CancelButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
    CancelButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [CancelButton addTarget:self action:@selector(cancelToppingView:) forControlEvents:UIControlEventTouchUpInside];
    
    [scrollView addSubview:CancelButton];
    
    y+=DoneButton.frame.size.height+10;
    
    [scrollView setContentSize:CGSizeMake(customView2.frame.size.width, y)];
}


-(void)createToppingViewForOffers_old
{
    SelVariantIndex = -1;
    
   // selToppings = [[NSMutableArray alloc] init];
//    if([[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] allKeys] containsObject:@"ProductToppings"])
//    {
//        selVariants = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"ProductComponents"];
//    }
    
    //selOfferToppings = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"ProductToppings"];
    //if()
    
    DeviceHeight = [UIScreen mainScreen].bounds.size.height;
    DeviceWidth = [UIScreen mainScreen].bounds.size.width;
    
    //AK :: create view using for reject appointment and assign appointment later when
    // user go to reject or assign the appointment later
    customView1 = [[UIView alloc] initWithFrame: CGRectMake ( 0, 0, DeviceWidth, DeviceHeight)];
    customView1.backgroundColor = [UIColor blackColor];
    customView1.alpha = 0.5;
    [[[UIApplication sharedApplication] keyWindow] addSubview:customView1];
    
    customView2 = [[UIView alloc] initWithFrame: CGRectMake ( 10, 40, customView1.frame.size.width-20, customView1.frame.size.height-80)];
    customView2.backgroundColor = [UIColor whiteColor];
    customView2.layer.cornerRadius = 4.0;
    customView2.layer.borderWidth = 0.5;
    //customView1.
    customView2.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [[[UIApplication sharedApplication] keyWindow] addSubview:customView2];
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, customView2.frame.size.width, customView2.frame.size.height)];
    scrollView.scrollEnabled = TRUE;
    scrollView.backgroundColor = [UIColor whiteColor];
    [customView2 addSubview:scrollView];
    
    UIView *vHeader = [[UIView alloc] initWithFrame: CGRectMake (0, 0, customView2.frame.size.width, 40)];
    vHeader.backgroundColor = [UIColor colorWithRed:179/255.0f green:93/255.0f blue:16/255.0f alpha:1.0f];
    vHeader.layer.cornerRadius = 0.0;
    vHeader.layer.borderWidth = 0.5;
    vHeader.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [scrollView addSubview:vHeader];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, vHeader.frame.size.width, 20)];
    lbl.text = @"Add Toppings";
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:14.0f];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.backgroundColor = [UIColor clearColor];
    [vHeader addSubview:lbl];
    
    int y = 10;
    
    y+=vHeader.frame.size.height+10;
     btnVarient = [[UIButton alloc] initWithFrame:CGRectMake(10, y, scrollView.frame.size.width-20, 40)];
    btnVarient.tag = 100;
    [btnVarient setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btnVarient.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    btnVarient.layer.borderColor = [UIColor blackColor].CGColor;
    btnVarient.layer.borderWidth = 0.5f;
    btnVarient.layer.cornerRadius = 4.0f;
    [scrollView addSubview:btnVarient];
    //Ashwani :: 0329_2016 Here check that variant is single or multiples
    if(selVariants.count>1)
    {
        //Ashwani :: March 03 2016 Drop Down Icon
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(btnVarient.frame.size.width-30, 5, 30, 30)];
        imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
        [btnVarient addSubview:imgView];
        [btnVarient setTitle:@"Select variant" forState:UIControlStateNormal];
        [btnVarient addTarget:self action:@selector(openPicker:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        SelVariantIndex=0;
        //This dict will use to add perticular variant topping products
        offerDict = [[NSMutableDictionary alloc] init];
        [btnVarient setTitle:[[selVariants objectAtIndex:SelVariantIndex] valueForKey:@"DisplayName"] forState:UIControlStateNormal];
        NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
        arrDict = [selVariants objectAtIndex:0];
        NSMutableArray *arrProductVarOptions = [arrDict valueForKey:@"LstProductVariantOptions"];
        NSMutableArray *offerIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
        if([offerIndexes containsObject:[@(SelOfferIndex) stringValue]])
        {
            int index = (int)[offerIndexes indexOfObject:[@(SelOfferIndex) stringValue]];
            [selOfferToppings removeObjectAtIndex:index];
        }
        for(int i = 0; i < arrProductVarOptions.count; i++)
        {
            NSString *key = [NSString stringWithFormat:@"ProductOptTopping%d%d",SelVariantIndex, i];
            selToppings = [offerDict valueForKey:key];
            NSString *str = @"";
            for(int j = 0; j < [selToppings count]; j++)
            {
                if(j > 0)
                    str = [str stringByAppendingFormat:@" & %@ ",[[selToppings objectAtIndex:j] valueForKey:@"Name"]];
                else
                    str = [NSString stringWithFormat:@"%@ ",[[selToppings objectAtIndex:j] valueForKey:@"Name"]];
            }
            
            UIButton *btn = (UIButton *)[customView2 viewWithTag:i+40000];
            if(![str isEqualToString:@""])
                [btn setTitle:str forState:UIControlStateNormal];
            else
                [btn setTitle:@"Please select toppings" forState:UIControlStateNormal];
        }
    }
    
    
     y += btnVarient.frame.size.height+10;
    
    NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
    arrDict = [selVariants objectAtIndex:0];
    NSMutableArray *arrProductVarOptions = [arrDict valueForKey:@"LstProductVariantOptions"];
        
    for(int i = 0; i < arrProductVarOptions.count; i++)
    {
        NSString *itemSelect = [[arrProductVarOptions objectAtIndex:i] valueForKey:@"VariantMaxSelect"];
        if(itemSelect != (id)[NSNull null])
        {
            UILabel *lblToppName = [[UILabel alloc] initWithFrame:CGRectMake(10, y, scrollView.frame.size.width-20, 20)];
            lblToppName.text = [[arrProductVarOptions objectAtIndex:i ]  valueForKey:@"VariantOption"];
            lblToppName.textColor = [UIColor blackColor];
            lblToppName.font = [UIFont systemFontOfSize:12.0f];
            lblToppName.textAlignment = NSTextAlignmentLeft;
            lblToppName.backgroundColor = [UIColor clearColor];
            lblToppName.adjustsFontSizeToFitWidth = YES;
            [scrollView addSubview:lblToppName];
            
            y+=lblToppName.frame.size.height+5;
            
            UIButton *productOptButton = [UIButton buttonWithType:UIButtonTypeCustom];
            productOptButton.frame = CGRectMake(10, y, scrollView.frame.size.width-20, 30);
            productOptButton.showsTouchWhenHighlighted = YES;
            [productOptButton setBackgroundColor:[UIColor  clearColor]];
            productOptButton.tag = i+40000;
            [productOptButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            productOptButton.layer.cornerRadius = 4.0f;
            productOptButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            productOptButton.layer.borderWidth = 0.3;
            productOptButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
            [productOptButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
            productOptButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
            
            //Ashwani ":: set the selected text on button from heer
            [productOptButton setTitle:@"Please select toppings" forState:UIControlStateNormal];
            
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(productOptButton.frame.size.width-30, 0, 30, 30)];
            imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
            [productOptButton addSubview:imgView];
            [productOptButton addTarget:self action:@selector(createTblToppingPicker:) forControlEvents:UIControlEventTouchUpInside];
            [scrollView addSubview:productOptButton];
            
            y+=productOptButton.frame.size.height+10;
            
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, y, scrollView.frame.size.width, 1)];
            separator.backgroundColor = [UIColor blackColor];
            [scrollView addSubview:separator];
            
            y+=separator.frame.size.height+20;
        }
    }
    
    
    y+=20;
    
    UIButton *DoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    DoneButton.frame = CGRectMake(20, y, (scrollView.frame.size.width-60)/2, 40);
    DoneButton.showsTouchWhenHighlighted = YES;
    [DoneButton setBackgroundColor:[UIColor colorWithRed:70/255.0f green:156/255.0f blue:158/255.0f alpha:1.0f]];
    [DoneButton setTitle:@"Add" forState:UIControlStateNormal];
    [DoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    DoneButton.layer.cornerRadius = 4.0f;
    DoneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    DoneButton.layer.borderWidth = 0.3;
    DoneButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [DoneButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
    DoneButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [DoneButton addTarget:self action:@selector(SaveToppingsTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [scrollView addSubview:DoneButton];
    
    UIButton *CancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CancelButton.frame = CGRectMake(DoneButton.frame.size.width+40, y, (scrollView.frame.size.width-60)/2, 40);
    CancelButton.showsTouchWhenHighlighted = YES;
    [CancelButton setBackgroundColor:[UIColor redColor]];
    [CancelButton setTitle:@"Skip" forState:UIControlStateNormal];
    [CancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    CancelButton.layer.cornerRadius = 4.0f;
    CancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    CancelButton.layer.borderWidth = 0.3;
    CancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [CancelButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
    CancelButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [CancelButton addTarget:self action:@selector(cancelToppingView:) forControlEvents:UIControlEventTouchUpInside];
    
    [scrollView addSubview:CancelButton];
    
    y+=DoneButton.frame.size.height+10;
    
    [scrollView setContentSize:CGSizeMake(customView2.frame.size.width, y)];
}

-(IBAction)openPicker:(id)sender
{
    //Ashwani :: Oct 20 2015 Check here forthe item are multiple selection or not
    viewHeader = [[UIView alloc] initWithFrame:CGRectMake(0, customView2.frame.size.height-270, customView2.frame.size.width, 270)];
    viewHeader.backgroundColor = [UIColor darkGrayColor];
    [customView2 addSubview:viewHeader];
    
    tblOfferVarients= [[UITableView alloc] initWithFrame:CGRectMake(0, 50, viewHeader.frame.size.width, 220) style:UITableViewStylePlain];
    tblOfferVarients.dataSource = self;
    tblOfferVarients.delegate = self;
    tblOfferVarients.tag = SelOfferIndex;
    [tblOfferVarients setBackgroundColor:[UIColor whiteColor]];
    [viewHeader addSubview:tblOfferVarients];
    
    componentPickerDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    componentPickerDoneButton.frame = CGRectMake(viewHeader.frame.size.width-80, 10, 60, 30);
    [componentPickerDoneButton addTarget:self action:@selector(variantPickerDoneTapped:) forControlEvents:UIControlEventTouchUpInside];
    componentPickerDoneButton.showsTouchWhenHighlighted = YES;
    [componentPickerDoneButton setTitle:@"Done" forState:UIControlStateNormal];
    [viewHeader addSubview:componentPickerDoneButton];
    
    return;
}

-(void) variantPickerDoneTapped:(id) sender {
    
    if(SelVariantIndex==-1)
        return;
    //This dict will use to add perticular variant topping products
    offerDict = [[NSMutableDictionary alloc] init];
    [btnVarient setTitle:[[selVariants objectAtIndex:SelVariantIndex] valueForKey:@"DisplayName"] forState:UIControlStateNormal];
    
    NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
    arrDict = [selVariants objectAtIndex:0];
    NSMutableArray *arrProductVarOptions = [arrDict valueForKey:@"LstProductVariantOptions"];
    NSMutableArray *offerIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
    if([offerIndexes containsObject:[@(SelOfferIndex) stringValue]])
    {
        NSMutableArray *varIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
        if([varIndexes containsObject:[@(SelVariantIndex) stringValue]])
        {
            int index = (int)[varIndexes indexOfObject:[@(SelVariantIndex) stringValue]];
            [selOfferToppings removeObjectAtIndex:index];
        }
        //[selOfferToppings removeObjectAtIndex:index];
    }
    
    
    for(int i = 0; i < arrProductVarOptions.count; i++)
    {
        NSString *key = [NSString stringWithFormat:@"ProductOptTopping%d%d",SelVariantIndex, i];
        selToppings = [offerDict valueForKey:key];
        
         NSString *str = @"";
         for(int j = 0; j < [selToppings count]; j++)
         {
             if(j > 0)
                 str = [str stringByAppendingFormat:@" & %@ ",[[selToppings objectAtIndex:j] valueForKey:@"Name"]];
             else
                 str = [NSString stringWithFormat:@"%@ ",[[selToppings objectAtIndex:j] valueForKey:@"Name"]];
         }
        
        UIButton *btn = (UIButton *)[customView2 viewWithTag:i+40000];
        if(![str isEqualToString:@""])
            [btn setTitle:str forState:UIControlStateNormal];
        else
            [btn setTitle:@"Please select toppings" forState:UIControlStateNormal];
    }
    [viewHeader removeFromSuperview];
}

-(IBAction)createTblToppingPicker:(id)sender
{
    int tag = (int)[sender tag];
    if(tag >=1000 && tag <1100)
    {
        SelVariantIndex = 0;
    }
    else if(tag >=2000 && tag <2100)
    {
        SelVariantIndex = 1;
    }
    else if(tag >=3000 && tag <3100)
    {
        SelVariantIndex = 2;
    }
    else if(tag >=4000 && tag <4100)
    {
        SelVariantIndex = 3;
    }
    else if(tag >=5000 && tag <5100)
    {
        SelVariantIndex = 4;
    }
    
    
    
    
    /*
     //This dict will use to add perticular variant topping products
     offerDict = [[NSMutableDictionary alloc] init];
     [btnVarient setTitle:[[selVariants objectAtIndex:SelVariantIndex] valueForKey:@"DisplayName"] forState:UIControlStateNormal];
     
     NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
     arrDict = [selVariants objectAtIndex:0];
     NSMutableArray *arrProductVarOptions = [arrDict valueForKey:@"LstProductVariantOptions"];
     NSMutableArray *offerIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
     if([offerIndexes containsObject:[@(SelOfferIndex) stringValue]])
     {
     NSMutableArray *varIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
     if([varIndexes containsObject:[@(SelVariantIndex) stringValue]])
     {
     int index = (int)[varIndexes indexOfObject:[@(SelVariantIndex) stringValue]];
     [selOfferToppings removeObjectAtIndex:index];
     }
     //[selOfferToppings removeObjectAtIndex:index];
     }
     
     
     for(int i = 0; i < arrProductVarOptions.count; i++)
     {
     NSString *key = [NSString stringWithFormat:@"ProductOptTopping%d%d",SelVariantIndex, i];
     selToppings = [offerDict valueForKey:key];
     
     NSString *str = @"";
     for(int j = 0; j < [selToppings count]; j++)
     {
     if(j > 0)
     str = [str stringByAppendingFormat:@" & %@ ",[[selToppings objectAtIndex:j] valueForKey:@"Name"]];
     else
     str = [NSString stringWithFormat:@"%@ ",[[selToppings objectAtIndex:j] valueForKey:@"Name"]];
     }
     
     UIButton *btn = (UIButton *)[customView2 viewWithTag:i+40000];
     if(![str isEqualToString:@""])
     [btn setTitle:str forState:UIControlStateNormal];
     else
     [btn setTitle:@"Please select toppings" forState:UIControlStateNormal];
     }
     
     
     
     */
    
    
    //Ashwani :: Nov 10 2015
    if(SelVariantIndex == -1)
        return;
    
    if(selToppings == nil)
        selToppings = [[NSMutableArray alloc] init];
    
    MinSelectToppings = -1;
    MaxSelectToppings = -1;
    
    [viewToppingHeader removeFromSuperview];
    toppingPickerOptionArray = [[NSMutableArray alloc] init];
    
    NSMutableArray *arrOptions;
    NSMutableDictionary *dictTemp;
    arrOptions = [[selVariants objectAtIndex:SelVariantIndex ] valueForKey:@"LstProductVariantOptions"];
    dictTemp = [selVariants objectAtIndex:SelVariantIndex];
    
    selToppingIndex = -1;
    if(tag >=1000 && tag <1100)
    {
        selToppingIndex = (int)[sender tag]-1000;
    }
    else if(tag >=2000 && tag <2100)
    {
        selToppingIndex = (int)[sender tag]-2000;
    }
    else if(tag >=3000 && tag <3100)
    {
        selToppingIndex = (int)[sender tag]-3000;
    }
    else if(tag >=4000 && tag <4100)
    {
        selToppingIndex = (int)[sender tag]-4000;
    }
    else if(tag >=5000 && tag <5100)
    {
        selToppingIndex = (int)[sender tag]-5000;
    }
    
    //Ashwani :: Here get max select from sub array
    
    NSString *optionId = [[[arrOptions objectAtIndex:selToppingIndex] valueForKey:@"VariantOptionId"] stringValue];
    maxselect = [[[arrOptions objectAtIndex:selToppingIndex] valueForKey:@"VariantMaxSelect"] intValue];
    
    //Ashwani:: Nov 10 2015
    MinSelectToppings = [[[arrOptions objectAtIndex:selToppingIndex] valueForKey:@"VariantMinSelect"] intValue];
    MaxSelectToppings = [[[arrOptions objectAtIndex:selToppingIndex] valueForKey:@"VariantMaxSelect"] intValue];
    
    for(int i = 0 ; i < [prodOptionsItemArr count]; i++)
    {
        if([[[[prodOptionsItemArr objectAtIndex:i] valueForKey:@"OptionId"] stringValue] isEqualToString:optionId])
        {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            dict = [[prodOptionsItemArr objectAtIndex:i] mutableCopy];
            [dict setObject:[dictTemp valueForKey:@"ProductVariantId"] forKey:@"ProductVariantId"];
            [toppingPickerOptionArray addObject:dict];
        }
    }
    
    //Ashwani :: Oct 20 2015 Check here forthe item are multiple selection or not
    viewToppingHeader = [[UIView alloc] initWithFrame:CGRectMake(0, DeviceHeight-270, DeviceWidth, 270)];
    viewToppingHeader.backgroundColor = [UIColor darkGrayColor];
    [[[UIApplication sharedApplication] keyWindow] addSubview:viewToppingHeader];
    
    tblToppingPicker = [[UITableView alloc] initWithFrame:CGRectMake(0, 35, DeviceWidth, viewToppingHeader.frame.size.height- 35) style:UITableViewStylePlain];
    tblToppingPicker.dataSource = self;
    tblToppingPicker.delegate = self;
    tblToppingPicker.tag = [sender tag];
    [tblToppingPicker setBackgroundColor:[UIColor whiteColor]];
    [viewToppingHeader addSubview:tblToppingPicker];
    
    ToppingDoneButtonTapped = [UIButton buttonWithType:UIButtonTypeCustom];
    ToppingDoneButtonTapped.frame = CGRectMake(DeviceWidth-65, 0, 60, 30);
    [ToppingDoneButtonTapped addTarget:self action:@selector(DoneButtonTappedToppingPicker:) forControlEvents:UIControlEventTouchUpInside];
    ToppingDoneButtonTapped.showsTouchWhenHighlighted = YES;
    [ToppingDoneButtonTapped setTitle:@"Done" forState:UIControlStateNormal];
    [viewToppingHeader addSubview:ToppingDoneButtonTapped];
}

-(IBAction)DoneButtonTappedToppingPicker:(id)sender
{
    if(selToppings.count<MinSelectToppings)
    {
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Voujon"
                                                         message:[@"Select at least " stringByAppendingFormat:@"%d items",MinSelectToppings]
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil, nil];
            [al show];
            return;
       
    }
    
    if(selToppings.count>0)
    {
        NSString *key  = [NSString stringWithFormat:@"ProductOptTopping%d%d",SelVariantIndex,selToppingIndex];
        [offerDict setObject:[@(SelVariantIndex) stringValue] forKey:@"SelVariantIndex"];
        [offerDict setObject:[@(SelOfferIndex) stringValue] forKey:@"SelOfferIndex"];
        [offerDict setObject:selToppings forKey:key];
        
        
        NSString *prodComp = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"DisplayName"];
        [offerDict setObject:prodComp forKey:@"ProductComponent"];
    }
    selToppings = [[NSMutableArray alloc] init];
    
    //Ashwani :: March 03
    if(offerDict.count>0)
    {
        NSMutableArray *arrOfferIndex = [selOfferToppings valueForKey:@"SelOfferIndex"];
        if([arrOfferIndex containsObject:[@(SelOfferIndex) stringValue]])
        {
            int offerInd = (int)[arrOfferIndex indexOfObject:[@(SelOfferIndex) stringValue]];
            
            //NSMutableDictionary *dict = [selOfferToppings objectAtIndex:offerInd];
            [selOfferToppings replaceObjectAtIndex:offerInd withObject:offerDict];
            
//            NSMutableArray *arrVariantIndex = [selOfferToppings valueForKey:@"SelVariantIndex"];
//            if([arrVariantIndex containsObject:[@(SelVariantIndex) stringValue]])
//            {
//                int index = (int)[arrVariantIndex indexOfObject:[@(SelVariantIndex) stringValue]];
//                [selOfferToppings replaceObjectAtIndex:index withObject:offerDict];
//            }
//            else
//            {
//                [selOfferToppings addObject:offerDict];
//            }
        }
        else
        {
            [selOfferToppings addObject:offerDict];
        }
        
        //return;
    }
    
    
    [viewToppingHeader removeFromSuperview];
    
}

-(IBAction)SaveToppingsTapped:(id)sender
{
    NSLog(@"Sel offer index : %d", SelOfferIndex);
    BOOL IsError = FALSE;
    for(int i = 0; i < selVariants.count; i++)
    {
        NSMutableArray *arrToppingOpt = [[selVariants objectAtIndex:i] valueForKey:@"LstProductVariantOptions"];
        for(int j = 0; j < arrToppingOpt.count;j++)
        {
            int varMinSelect = [[[arrToppingOpt objectAtIndex:j] valueForKey:@"VariantMinSelect"] intValue];
            NSString *key = [NSString stringWithFormat:@"ProductOptTopping%d%d",i,j];
            if(varMinSelect > 0)
            {
                NSMutableArray *offerIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
                if(offerIndexes.count>0)
                {
                    int index = -1;
                    index = (int)[offerIndexes indexOfObject:[@(SelOfferIndex) stringValue]];
                    if(index != -1)
                    {
                        NSMutableArray *topp = [[selOfferToppings objectAtIndex:index ] valueForKey:key];
                        if(varMinSelect > 0 && (topp.count==0))
                        {
                            //ProductOptTopping00
                            IsError = TRUE;
                            break;
                            
                        }
                    }
                    else
                    {
                        IsError = TRUE;
                        break;
                    }
                }
                else
                {
                    IsError = TRUE;
                    break;
                }
                
            }
        }
        if(IsError)
            break;
    }
    
    if(IsError)
    {
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Message"
                                                     message:[@"Select toppings for all" stringByAppendingFormat:@" items"]
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil, nil];
        [al show];
        return;
    }
    
    NSString *key = [NSString stringWithFormat:@"%@%d",@"CompTopping",SelOfferIndex];
    [compToppings setObject:selOfferToppings forKey:key];
    
    //Ashwani :: Oct 30 2015 //set price here for item
    float StandardOfferPrice = 0.0f;
    NSString *strStandardOfferPrice;
    NSString *offerPrice = [[selectedComponentPickerContent objectAtIndex:0] valueForKey:@"offerPrice"];
    
    if([offerPrice isEqualToString:@"0.00"])
    {
        StandardOfferPrice = 0.0f;
        for(int i = 0; i < [selectedComponentPickerContent count]; i++)
        {
            BOOL isOption = [[[selectedComponentPickerContent objectAtIndex:i] valueForKey:@"IsOptionsExist"] boolValue];
            if(isOption)
            {
                NSMutableArray *arrProdComp = [[selectedComponentPickerContent objectAtIndex:i] valueForKey:@"ProductComponents"];
                for(int j = 0; j < arrProdComp.count; j++)
                {
                    NSString *price = [[arrProdComp objectAtIndex:j] valueForKey:@"Price"];
                    if(price != (id)[NSNull null])
                        StandardOfferPrice = StandardOfferPrice+[price floatValue];
                }
            }
        }
    }
    else
    {
        StandardOfferPrice = [offerPrice floatValue];
    }
    
    //NSMutableArray *arrKeys = (NSMutableArray *)[compToppings allKeys];
    //for(int  i = 0; i < arrKeys.count; i++)
    //{
       // NSMutableArray *arrObj = [compToppings valueForKey:[arrKeys objectAtIndex:i]];
    NSMutableArray *arrObj = selOfferToppings;
       // NSLog(@"arrObj %@", arrObj);
        for(int j = 0; j < arrObj.count; j++)
        {
            NSMutableArray *arrKey2 = (NSMutableArray *)[[arrObj objectAtIndex:j] allKeys];
            //if(arrKey2 containsObject:<#(nonnull id)#>)
            for(int k = 0; k < arrKey2.count; k++)
            {
                if([[arrKey2 objectAtIndex:k] containsString:@"ProductOptTopping"])
                {
                    NSMutableArray *arrObj2 = [[arrObj objectAtIndex:j] valueForKey:[arrKey2 objectAtIndex:k]];
                    for(int l = 0; l < arrObj2.count; l++)
                    {
                        NSString *price = [[arrObj2 objectAtIndex:l] valueForKey:@"Price"];
                        if(price != (id)[NSNull null])
                            StandardOfferPrice = StandardOfferPrice+[price floatValue];
                    }
                    
                }
            }
        }
   // }
    strStandardOfferPrice = [NSString stringWithFormat:@"£%.02f",StandardOfferPrice];
    /*--------------- END --------------------------*/
    
    ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
    cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
    
    //Ashwani :: Set price here for items selected with offers
    if(strStandardOfferPrice != nil && (![strStandardOfferPrice isEqualToString:@""]))
        cell.optionsPriceLbl.text = strStandardOfferPrice;
    
    
    [viewToppingHeader removeFromSuperview];
    [customView1 removeFromSuperview];
    [customView2 removeFromSuperview];
    SelVariantIndex = -1;
    //****************
    return;
}

-(void)cancelToppingView:(id)sender
{
    [viewToppingHeader removeFromSuperview];
    [customView1 removeFromSuperview];
    [customView2 removeFromSuperview];
}

#pragma mark -  offers Topping EnD -

-(void)pickerViewDoneButtonTapped:(id)sender{
    NSLog(@"Done tapped");
    ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
    cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
   if(isSetMealView)
    {
        NSString * str = [selectedPickerContent valueForKey:@"DisplayName"];
        UITextField* txtMeal = (UITextField *)[cell viewWithTag:txtTag];
        txtMeal.text = str;
    }else
    {
        NSString * str = [selectedPickerContent valueForKey:@"DisplayName"];
        cell.variantTxtField.text = str;
        cell.optionsPriceLbl.text = [NSString stringWithFormat:@"£%@",[selectedPickerContent valueForKey:@"Price"]];
    }
    
    [self.view endEditing:YES];
    [viewHeader removeFromSuperview];
    [tableViewOptPicker removeFromSuperview];
    [prodOptionPicker removeFromSuperview];
    [prodOptionPickerDoneButton removeFromSuperview];
    
    //Ashwani :: Nov 17, 2015 Here the flow for product options will be start by checking product options
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    arr = [selectedPickerContent valueForKey:@"ProductVariantOptions"];
    if(arr.count > 0)
        [self createToppingViewForStandard];
}

#pragma mark - Standard product toppings -
-(void)createToppingViewForStandard
{
    DeviceHeight = [UIScreen mainScreen].bounds.size.height;
    DeviceWidth = [UIScreen mainScreen].bounds.size.width;
    
    //AK :: create view using for reject appointment and assign appointment later when
    // user go to reject or assign the appointment later
    customView1 = [[UIView alloc] initWithFrame: CGRectMake ( 0, 0, DeviceWidth, DeviceHeight)];
    customView1.backgroundColor = [UIColor blackColor];
    customView1.alpha = 0.5;
    [[[UIApplication sharedApplication] keyWindow] addSubview:customView1];
    
    customView2 = [[UIView alloc] initWithFrame: CGRectMake ( 10, 40, customView1.frame.size.width-20, customView1.frame.size.height-80)];
    customView2.backgroundColor = [UIColor whiteColor];
    customView2.layer.cornerRadius = 4.0;
    customView2.layer.borderWidth = 0.5;
    //customView1.
    customView2.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [[[UIApplication sharedApplication] keyWindow] addSubview:customView2];
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, customView2.frame.size.width, customView2.frame.size.height)];
    scrollView.scrollEnabled = TRUE;
    scrollView.backgroundColor = [UIColor whiteColor];
    [customView2 addSubview:scrollView];
    
    UIView *vHeader = [[UIView alloc] initWithFrame: CGRectMake (0, 0, customView2.frame.size.width, 40)];
    vHeader.backgroundColor = [UIColor colorWithRed:179/255.0f green:93/255.0f blue:16/255.0f alpha:1.0f];
    vHeader.layer.cornerRadius = 0.0;
    vHeader.layer.borderWidth = 0.5;
    vHeader.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [scrollView addSubview:vHeader];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, vHeader.frame.size.width, 20)];
    lbl.text = @"Add Toppings";
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:14.0f];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.backgroundColor = [UIColor clearColor];
    [vHeader addSubview:lbl];
    
    int y = 10;
    
    y+=vHeader.frame.size.height+10;
    arrToppings = [[NSMutableArray alloc] init];
    arrToppings = [selectedPickerContent valueForKey:@"ProductVariantOptions"];
    for(int i = 0; i < arrToppings.count; i++)
    {
        
        NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
        arrDict = [arrToppings objectAtIndex:i];
        
        UILabel *lblItemName = [[UILabel alloc] initWithFrame:CGRectMake(10, y, scrollView.frame.size.width-20, 20)];
        lblItemName.text = [arrDict  valueForKey:@"Option"];
        lblItemName.textColor = [UIColor blackColor];
        lblItemName.textAlignment = NSTextAlignmentLeft;
        lblItemName.backgroundColor = [UIColor clearColor];
        lblItemName.font = [UIFont systemFontOfSize:12.0f];
        lblItemName.adjustsFontSizeToFitWidth = YES;
        [scrollView addSubview:lblItemName];
        
        y+=lblItemName.frame.size.height+10;
        
        UIButton *productOptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        productOptButton.frame = CGRectMake(10, y, scrollView.frame.size.width-20, 30);
        productOptButton.showsTouchWhenHighlighted = YES;
        [productOptButton setBackgroundColor:[UIColor  clearColor]];
        
        productOptButton.tag = i+20000;
        [productOptButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        productOptButton.layer.cornerRadius = 4.0f;
        productOptButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        productOptButton.layer.borderWidth = 0.3;
        productOptButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [productOptButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
        productOptButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        
        //************************************************************************************
        //Ashwani :: Here set options if already selected by user
        
        NSMutableArray *selectedProdVarId = [selectedToppings valueForKey:@"ProductVariantId"];
        //Ashwani ":: set the selected text on button from heer
        NSString *str = @"";
        if([selectedProdVarId containsObject:[arrDict valueForKey:@"ProductVariantId"]])
        {
            int index = (int)[selectedProdVarId indexOfObject:[arrDict valueForKey:@"ProductVariantId"]];
            NSMutableArray *tempArr = [[selectedToppings objectAtIndex:index] valueForKey:@"ProductOptions"];
            for(int i = 0; i < [tempArr count]; i++)
            {
                if(i > 0)
                    str = [str stringByAppendingFormat:@" & %@ ",[[tempArr objectAtIndex:i] valueForKey:@"Name"]];
                else
                    str = [NSString stringWithFormat:@"%@ ",[[tempArr objectAtIndex:i] valueForKey:@"Name"]];
            }
            [productOptButton setTitle:str forState:UIControlStateNormal];
        }
        else
        {
            if(selectedToppings.count>0)
            {
                selectedToppings = [[NSMutableArray alloc] init];
            }
            [productOptButton setTitle:@"Please select toppings" forState:UIControlStateNormal];
        }
        
        
        //**************************************************************************************
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(productOptButton.frame.size.width-30, 0, 30, 30)];
        imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
        [productOptButton addSubview:imgView];
        [productOptButton addTarget:self action:@selector(createTblToppingPickerForStandard:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:productOptButton];
        
        y+=productOptButton.frame.size.height+10;
        
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, y, scrollView.frame.size.width, 1)];
        separator.backgroundColor = [UIColor blackColor];
        [scrollView addSubview:separator];
        
        y+=separator.frame.size.height+20;
    }
    
    y+=20;
    
    UIButton *DoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    //
    //DoneButton.frame = CGRectMake(20, y, (scrollView.frame.size.width-60)/2, 40);
    DoneButton.frame = CGRectMake((scrollView.frame.size.width/2)-100, y, 200, 40);
    DoneButton.showsTouchWhenHighlighted = YES;
    [DoneButton setBackgroundColor:[UIColor colorWithRed:179/255.0f green:93/255.0f blue:16/255.0f alpha:1.0f]];
    [DoneButton setTitle:@"Add" forState:UIControlStateNormal];
    [DoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    DoneButton.layer.cornerRadius = 4.0f;
    DoneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    DoneButton.layer.borderWidth = 0.3;
    DoneButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [DoneButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
    DoneButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [DoneButton addTarget:self action:@selector(SaveToppingsTappedForStandard:) forControlEvents:UIControlEventTouchUpInside];
    
    [scrollView addSubview:DoneButton];
    
    UIButton *CancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CancelButton.frame = CGRectMake(DoneButton.frame.size.width+40, y, (scrollView.frame.size.width-60)/2, 40);
    CancelButton.showsTouchWhenHighlighted = YES;
    [CancelButton setBackgroundColor:[UIColor redColor]];
    [CancelButton setTitle:@"Skip" forState:UIControlStateNormal];
    [CancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    CancelButton.layer.cornerRadius = 4.0f;
    CancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    CancelButton.layer.borderWidth = 0.3;
    CancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [CancelButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
    CancelButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [CancelButton addTarget:self action:@selector(cancelToppingView:) forControlEvents:UIControlEventTouchUpInside];
    
    //[scrollView addSubview:CancelButton];
    
    y+=DoneButton.frame.size.height+10;
    
    [scrollView setContentSize:CGSizeMake(customView2.frame.size.width, y)];
}

-(IBAction)createTblToppingPickerForStandard:(id)sender
{
    //Ashwani :: Nov 10 2015
    MinSelectToppings = -1;
    MaxSelectToppings = -1;
    
    [viewToppingHeader removeFromSuperview];
    toppingPickerOptionArray = [[NSMutableArray alloc] init];
    int tag = (int)[sender tag]- 20000;
    
    strOptionId = [[[arrToppings objectAtIndex:tag] valueForKey:@"OptionId"] stringValue];
    selectedDict = [[NSMutableDictionary alloc] init];
    selectedDict = [arrToppings objectAtIndex:tag];
    maxselect = [[[arrToppings objectAtIndex:tag] valueForKey:@"MaxSelect"] intValue];
    
    MinSelectToppings = [[[arrToppings objectAtIndex:tag] valueForKey:@"MinSelect"] intValue];
    MaxSelectToppings = [[[arrToppings objectAtIndex:tag] valueForKey:@"MaxSelect"] intValue];
    
    for(int i = 0 ; i < [prodOptionsItemArr count]; i++)
    {
        if([[[[prodOptionsItemArr objectAtIndex:i] valueForKey:@"OptionId"] stringValue] isEqualToString:strOptionId])
        {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            dict = [[prodOptionsItemArr objectAtIndex:i] mutableCopy];
            [dict setObject:[selectedPickerContent valueForKey:@"ProductVariantId"]  forKey:@"ProductVariantId"];
            [toppingPickerOptionArray addObject:dict];
            NSLog(@"selectedPickerContent: %@",selectedPickerContent);
            NSLog(@"dict: %@",dict);
        }
    }
    
    //Ashwani :: Oct 20 2015 Check here forthe item are multiple selection or not
    viewToppingHeader = [[UIView alloc] initWithFrame:CGRectMake(0, DeviceHeight-270, DeviceWidth, 270)];
    viewToppingHeader.backgroundColor = [UIColor darkGrayColor];
    [[[UIApplication sharedApplication] keyWindow] addSubview:viewToppingHeader];
    
    tblToppingPickerForStandard = [[UITableView alloc] initWithFrame:CGRectMake(0, 35, DeviceWidth, viewToppingHeader.frame.size.height- 35) style:UITableViewStylePlain];
    tblToppingPickerForStandard.dataSource = self;
    tblToppingPickerForStandard.delegate = self;
    tblToppingPickerForStandard.tag = tag;
    [tblToppingPickerForStandard setBackgroundColor:[UIColor whiteColor]];
    [viewToppingHeader addSubview:tblToppingPickerForStandard];
    
    ToppingDoneButtonTapped = [UIButton buttonWithType:UIButtonTypeCustom];
    ToppingDoneButtonTapped.frame = CGRectMake(DeviceWidth-65, 0, 60, 30);
    [ToppingDoneButtonTapped addTarget:self action:@selector(DoneButtonTappedToppingPickerForStandard:) forControlEvents:UIControlEventTouchUpInside];
    ToppingDoneButtonTapped.showsTouchWhenHighlighted = YES;
    [ToppingDoneButtonTapped setTitle:@"Done" forState:UIControlStateNormal];
    [viewToppingHeader addSubview:ToppingDoneButtonTapped];
}

-(IBAction)DoneButtonTappedToppingPickerForStandard:(id)sender
{
    //Ashwwani :: Nov 16,2015 Check here for minimum selection of items if exist
    for(int  i =0 ; i < arrToppings.count; i ++)
    {
        NSMutableArray *arr = [selectedToppings valueForKey:@"OptionId"];
        if([arr containsObject:[selectedDict valueForKey:@"OptionId"]])
        {
            int index  = (int)[arr indexOfObject:[selectedDict valueForKey:@"OptionId"]];
            NSMutableArray  *arr1 = [[NSMutableArray alloc] init];
            arr1 = [[selectedToppings objectAtIndex:index] valueForKey:@"ProductOptions"];
            if(arr1.count < MinSelectToppings)
            {
                UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Message"
                                                             message:[@"Select at least " stringByAppendingFormat:@"%d items",MinSelectToppings]
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
                [al show];
                return;
            }
        }
    }
    
    [viewToppingHeader removeFromSuperview];
}

-(IBAction)SaveToppingsTappedForStandard:(id)sender
{
    ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
    cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
    //Ashwani :: March 03
    BOOL isError = false;
    for(int  i =0 ; i < arrToppings.count; i ++)
    {
        NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
        arrDict = [arrToppings objectAtIndex:i];
        NSMutableArray *optionIDArr = [selectedToppings valueForKey:@"OptionId"];
        if(![optionIDArr containsObject:[arrDict valueForKey:@"OptionId"]] && [[arrDict objectForKey:@"MinSelect"] intValue] > 0)
        {
            isError = true;
            break;
        }
    }
    
    if(isError)
    {
        [SVProgressHUD showErrorWithStatus:@"Select topping options."];
    }
    else
    {
        float ToppingPrice = 0.0;
        NSString *strToppingPrice = @"";
        for(int i = 0; i < [selectedToppings count]; i++)
        {
            NSMutableDictionary *dict = [selectedToppings objectAtIndex:i];
            NSMutableArray *arrTemp = [dict valueForKey:@"ProductOptions"];
            for(int j = 0; j < arrTemp.count; j++)
            {
                NSString *price = [[arrTemp objectAtIndex:j] valueForKey:@"Price"];
                
                if(price != (id)[NSNull null])
                {
                    if(price != nil && (![price isEqualToString:@""]))
                        ToppingPrice = ToppingPrice+[price floatValue];
                    else
                        ToppingPrice = ToppingPrice+0.0f;
                }
                else
                    ToppingPrice = ToppingPrice+0.0f;
            }
            
        }
        
        //Ashwani :: Set price here for items selected with offers
        if(ToppingPrice != 0.0)
        {
            NSString *fixedPrice ;//= [cell.ItemPrice.text stringByReplacingOccurrencesOfString:@"£" withString:@""];
            fixedPrice = [selectedPickerContent valueForKey:@"Price"];
            
            ToppingPrice = [fixedPrice floatValue]+ToppingPrice;
            strToppingPrice = [NSString stringWithFormat:@"£%.02f",ToppingPrice];
            cell.optionsPriceLbl.text = strToppingPrice;
        }
        
        [viewToppingHeader removeFromSuperview];
        [customView1 removeFromSuperview];
        [customView2 removeFromSuperview];
    }
}

#pragma mark -  Standard Topping EnD -
-(void) strengthPickerViewDoneButtonTapped:(id) sender {
    
    ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
    cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
    cell.variantTxtField.text = [selectedStrengthPickerContent valueForKey:@"Name"];
    [self.view endEditing:YES];
    
}

-(void)prodOptionPickerDoneButtonTapped:(id)sender
{
    ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
    cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
    
    float StandardOfferPrice = 0.0f;
    
//    //Ashwwani :: Nov 16,2015 Check here for minimum selection of items if exist
//    if(arrSelectedprodOptionsPickerContent.count < minselect)
//     {
//         UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Message"
//                                                      message:[@"Select atleast " stringByAppendingFormat:@"%d items",minselect]
//                                                     delegate:self
//                                            cancelButtonTitle:@"OK"
//                                            otherButtonTitles:nil, nil];
//         [al show];
//         return;
//     }
    
    if(selectedPickerContent.count>0)
        StandardOfferPrice = StandardOfferPrice+[[selectedPickerContent valueForKey:@"Price"] floatValue];
    for(int i = 0; i < [arrSelectedprodOptionsPickerContent count]; i++)
    {
        NSString *price = [[arrSelectedprodOptionsPickerContent objectAtIndex:i] valueForKey:@"Price"];
        if(price !=(id)[NSNull null])
            StandardOfferPrice = StandardOfferPrice+[price floatValue];
    }
    //Ashwani :: Add price for other item here if exist
    NSString *strStandardOfferPrice = [NSString stringWithFormat:@"£%.02f",StandardOfferPrice];
    cell.optionsPriceLbl.text = strStandardOfferPrice;
    
    [viewHeader removeFromSuperview];
    [tableViewOptPicker removeFromSuperview];
    [prodOptionPicker removeFromSuperview];
    [prodOptionPickerDoneButton removeFromSuperview];
    
}


#pragma mark - Add Item To Cart -
-(void)addButtonTapped:(id)sender{
    
    BOOL isError = false;
    //Ashwani March 03
    BOOL isToppingError = false;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([sender tag]%1000) inSection:([sender tag]/1000)];
    
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    tmpArr  = [[SharedContent sharedInstance] cartArr];
    NSLog(@"Cart Array : %@ and Count :%lu", [[SharedContent sharedInstance] cartArr], (unsigned long)tmpArr.count);
    
    NSMutableDictionary* tmpCartDict = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"Products"] objectAtIndex:indexPath.row]];
    //Ashwani :: Check here for custom varients
    if(dict == nil || dict.count == 0) {
        dict = [[NSMutableDictionary alloc] initWithDictionary:[[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"CustomProducts"] objectAtIndex:indexPath.row]];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"isCustomProduct"];
    }
    else {
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"isCustomProduct"];
    }
    
    if ([[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"CategoryName"] containsString:@"VOUJON"]) {
        
         [tmpCartDict setObject:[dict valueForKey:@"Code"] forKey:@"Code"];
         [tmpCartDict setObject:[dict valueForKey:@"Description"] forKey:@"Description"];
         [tmpCartDict setObject:[dict valueForKey:@"DisplaySequence"] forKey:@"DisplaySequence"];
         [tmpCartDict setObject:[dict valueForKey:@"Name"] forKey:@"Name"];
         [tmpCartDict setObject:[dict valueForKey:@"ProductId"] forKey:@"ProductId"];
        
        [tmpCartDict setObject:[dict valueForKey:@"isCustomProduct"] forKey:@"isCustomProduct"];
        
        //Ashwani May 26, 2016:: Set here original price of product here
        if([dict valueForKey:@"Price"] != nil)
        {
            [tmpCartDict setObject:[dict valueForKey:@"Price"] forKey:@"OriginalPrice"];
        }
        else
        {
            if(selectedPickerContent != nil)
            {
                [tmpCartDict setObject:[selectedPickerContent valueForKey:@"Price"] forKey:@"OriginalPrice"];
            }
            else
            {
                [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] forKey:@"OriginalPrice"];
            }
        }
        
        if(selectedPickerContent != nil)
        {
            [tmpCartDict setObject:[selectedPickerContent valueForKey:@"Price"] forKey:@"Price"];
            [tmpCartDict setObject:[selectedPickerContent valueForKey:@"Name"] forKey:@"ProductVariantName"];
            [tmpCartDict setObject:[selectedPickerContent valueForKey:@"ProductVariantId"] forKey:@"ProductVariantId"];
            
        }
        else
        {
            [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] forKey:@"Price"];
            [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Name"] forKey:@"ProductVariantName"];
            [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"ProductVariantId"] forKey:@"ProductVariantId"];
        }
        
         
         float StandardOfferPrice = 0.0f;
         if(selectedPickerContent != nil)
         {
             if([selectedPickerContent valueForKey:@"Price"] != (id)[NSNull null])
                 StandardOfferPrice = StandardOfferPrice+[[selectedPickerContent valueForKey:@"Price"] floatValue];
         }
         else
         {
             if([[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] != (id)[NSNull null])
                 StandardOfferPrice = StandardOfferPrice+[[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] floatValue];
         }
        
        
        NSMutableArray *arrSelectedObj = [[NSMutableArray alloc] init];
        if(selectedStrengthPickerContent!=nil)
        {
            [arrSelectedObj addObject:selectedStrengthPickerContent];
        }
        
        //Ashwani :: Add selected item to array to show toppings selcted with items
        if(arrSelectedObj.count>0)
        {
            [tmpCartDict setObject:[@(arrSelectedObj.count) stringValue] forKey:@"ProductComponentsOptionsCount"];
            //these items will be selected if multiple items selected from the list
            //then items will be added to array
            for(int i = 0; i < [arrSelectedObj count]; i++)
            {
                NSString *itemNo = [@(i) stringValue];
                NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                [tmpCartDict setObject:[arrSelectedObj objectAtIndex:i] forKey:keyName];
                
                NSString *price = [[arrSelectedObj objectAtIndex:i] valueForKey:@"Price"];
                
                if(price != (id)[NSNull null])
                {
                    if(price != nil && (![price isEqualToString:@""]))
                        StandardOfferPrice = StandardOfferPrice+[price floatValue];
                    else
                        StandardOfferPrice = StandardOfferPrice+0.00;
                }
            }
        }
        selectedStrengthPickerContent = nil;
    }
    else {
    
        if ([[dict valueForKey:@"ProductVariants"] count] > 1) {
            [tmpCartDict setObject:[dict valueForKey:@"Code"] forKey:@"Code"];
            [tmpCartDict setObject:[dict valueForKey:@"Description"] forKey:@"Description"];
            [tmpCartDict setObject:[dict valueForKey:@"DisplaySequence"] forKey:@"DisplaySequence"];
            [tmpCartDict setObject:[dict valueForKey:@"Name"] forKey:@"Name"];
            [tmpCartDict setObject:[dict valueForKey:@"ProductId"] forKey:@"ProductId"];
            
            [tmpCartDict setObject:[dict valueForKey:@"isCustomProduct"] forKey:@"isCustomProduct"];
            
            //Ashwani May 26, 2016:: Set here original price of product here
            if([dict valueForKey:@"Price"] != nil)
            {
                [tmpCartDict setObject:[dict valueForKey:@"Price"] forKey:@"OriginalPrice"];
            }
            else
            {
                [tmpCartDict setObject:[selectedPickerContent valueForKey:@"Price"] forKey:@"OriginalPrice"];
            }
            
            [tmpCartDict setObject:[selectedPickerContent valueForKey:@"Price"] forKey:@"Price"];
            [tmpCartDict setObject:[selectedPickerContent valueForKey:@"Name"] forKey:@"ProductVariantName"];
            [tmpCartDict setObject:[selectedPickerContent valueForKey:@"ProductVariantId"] forKey:@"ProductVariantId"];
            float StandardOfferPrice = 0.0f;
            
            //Ashwani :: March 03, 2016 check here product varients topping is complsory or not
            NSMutableArray *arrVarOpt = [selectedPickerContent valueForKey:@"ProductVariantOptions"];
            for(int  i =0 ; i < arrVarOpt.count; i ++)
            {
                NSMutableDictionary *arrDict = [[NSMutableDictionary alloc] init];
                arrDict = [arrVarOpt objectAtIndex:i];
                NSMutableArray *optionIDArr = [selectedToppings valueForKey:@"OptionId"];
                if(![optionIDArr containsObject:[arrDict valueForKey:@"OptionId"]] && [[arrDict objectForKey:@"MinSelect"] intValue] > 0)
                {
                    isToppingError = true;
                    break;
                }
            }
            
            if([selectedPickerContent valueForKey:@"Price"] != (id)[NSNull null])
                StandardOfferPrice = StandardOfferPrice+[[selectedPickerContent valueForKey:@"Price"] floatValue];
            
            if(selectedprodOptionsPickerContent != nil && [selectedprodOptionsPickerContent count] != 0 )
            {
                [tmpCartDict setObject:[selectedprodOptionsPickerContent valueForKey:@"Name"]  forKey:@"ProductOptionName"];
                if([selectedprodOptionsPickerContent valueForKey:@"OptionId"] != (id)[NSNull null])
                    [tmpCartDict setObject:[selectedprodOptionsPickerContent valueForKey:@"OptionId"]  forKey:@"ProductOptionId"];
                else
                    [tmpCartDict setObject:[selectedprodOptionsPickerContent valueForKey:@"OptionItemId"]  forKey:@"ProductOptionId"];
            }
            else if(arrSelectedprodOptionsPickerContent.count>0)
            {
                [tmpCartDict setObject:[@(arrSelectedprodOptionsPickerContent.count) stringValue] forKey:@"ProductComponentsOptionsCount"];
                //these items will be selected if multiple items selected from the list
                //then items will be added to array
                for(int i = 0; i < [arrSelectedprodOptionsPickerContent count]; i++)
                {
                    NSString *itemNo = [@(i) stringValue];
                    NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                    [tmpCartDict setObject:[arrSelectedprodOptionsPickerContent objectAtIndex:i] forKey:keyName];
                    
                    NSString *price = [[arrSelectedprodOptionsPickerContent objectAtIndex:i] valueForKey:@"Price"];
                    
                    if(price != (id)[NSNull null])
                    {
                        if(price != nil && (![price isEqualToString:@""]))
                            StandardOfferPrice = StandardOfferPrice+[price floatValue];
                        else
                            StandardOfferPrice = StandardOfferPrice+0.00;
                    }
                }
                
                //Ashwani :: Add price for other item here if exist
                NSString *strStandardOfferPrice = [NSString stringWithFormat:@"%.02f",StandardOfferPrice];
                [tmpCartDict setObject:strStandardOfferPrice forKey:@"Price"];
            }
            else if(selectedToppings.count > 0)
            {
                int k = 0;
                for(int i = 0; i < [selectedToppings count]; i++)
                {
                    NSMutableDictionary *dictData = [selectedToppings objectAtIndex:i];
                    if([[[dictData valueForKey:@"ProductVariantId"] stringValue] isEqualToString:[[selectedPickerContent valueForKey:@"ProductVariantId"] stringValue]])
                    {
                        NSMutableArray *subArr = [dictData valueForKey:@"ProductOptions"];
                        for(int j = 0; j < subArr.count; j++)
                        {
                            NSString *itemNo = [@(k) stringValue];
                            NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                            [tmpCartDict setObject:[subArr objectAtIndex:j] forKey:keyName];
                            k++;
                            
                            NSString *price = [[subArr objectAtIndex:j] valueForKey:@"Price"];
                            
                            if(price != (id)[NSNull null])
                            {
                                if(price != nil && (![price isEqualToString:@""]))
                                    StandardOfferPrice = StandardOfferPrice+[price floatValue];
                                else
                                    StandardOfferPrice = StandardOfferPrice+0.00;
                            }
                        }
                    }
                }
                [tmpCartDict setObject:[@(k) stringValue] forKey:@"ProductComponentsOptionsCount"];
                //Ashwani :: Add price for other item here if exist
                NSString *strStandardOfferPrice = [NSString stringWithFormat:@"%.02f",StandardOfferPrice];
                [tmpCartDict setObject:strStandardOfferPrice forKey:@"Price"];
                /************************END******************************/
            }
            selectedprodOptionsPickerContent = [[NSMutableDictionary alloc] init];
            arrSelectedprodOptionsPickerContent = [[NSMutableArray alloc] init];
            selectedToppings = [[NSMutableArray alloc] init];
        }
        else if([[dict valueForKey:@"ProductComponents"] count] > 0)
        {
            [tmpCartDict setObject:[dict valueForKey:@"Code"] forKey:@"Code"];
            NSString *des;
            if([dict valueForKey:@"Description"] != nil || [dict valueForKey:@"Description"] != (id)[NSNull null])
                des = [dict valueForKey:@"Description"];
            else
                des = @"";
            
            [tmpCartDict setObject:des forKey:@"Description"];
            [tmpCartDict setObject:[dict valueForKey:@"DisplaySequence"] forKey:@"DisplaySequence"];
            [tmpCartDict setObject:[dict valueForKey:@"Name"] forKey:@"Name"];
            [tmpCartDict setObject:[dict valueForKey:@"ProductId"] forKey:@"ProductId"];
            
            [tmpCartDict setObject:[dict valueForKey:@"isCustomProduct"] forKey:@"isCustomProduct"];
            
            //Ashwani May 26, 2016:: Set here original price of product here
            if([dict valueForKey:@"Price"] != nil)
            {
                [tmpCartDict setObject:[dict valueForKey:@"Price"] forKey:@"OriginalPrice"];
            }
            //Ashwani :: Set price here for Bogof offers if anyone exist
            
            [tmpCartDict setObject:[dict valueForKey:@"Price"] forKey:@"Price"];
            //Ashwani :: Get item price here
            NSString *itemPrice = [dict valueForKey:@"Price"];
            float StandardOfferPrice = 0.0f;
            if(itemPrice != (id)[NSNull null])
            {
                
                if(itemPrice != nil && (![itemPrice isEqualToString:@""]))
                    StandardOfferPrice = StandardOfferPrice+[itemPrice floatValue];
            }
            /* -------------End--------------*/
            
            if(selectedComponentPickerContent.count > 0)
            {
                int prodCompOptCount = -1;
                //Ashwani :: Add multiple selections
                for(int i = 0; i < [selectedComponentPickerContent count]; i++)
                {
                    if([[dict valueForKey:@"Price"] isEqualToString:@"0.00"])
                    {
                        NSMutableArray *prodComp = [[selectedComponentPickerContent objectAtIndex:i] valueForKey:@"ProductComponents"];
                        for(int j = 0 ; j < prodComp.count; j++)
                        {
                            if([[prodComp objectAtIndex:j] valueForKey:@"Price"] != (id)[NSNull null])
                            {
                                StandardOfferPrice = StandardOfferPrice+[[[prodComp objectAtIndex:j] valueForKey:@"Price"] floatValue];
                            }
                        }
                        
                    }
                    
                    if ([[[selectedComponentPickerContent objectAtIndex:i] valueForKey:@"IsOptionsExist"] boolValue] || [[[selectedComponentPickerContent objectAtIndex:i] valueForKey:@"IsToppingsExist"] boolValue])
                    {
                        
                        NSMutableArray *tempArr = [[selectedComponentPickerContent objectAtIndex:i ] valueForKey:@"ProductComponents"];
                        if(tempArr.count==0)
                        {
                            isError = YES;
                            break;
                        }
                        
                        if(tempArr.count==1)
                        {
                            for(int j = 0; j < tempArr.count; j++)
                            {
                                NSMutableDictionary *dicTemp = [tempArr objectAtIndex:j];
                                prodCompOptCount++;
                                NSString *itemNo = [@(prodCompOptCount) stringValue];
                                NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                                [tmpCartDict setObject:dicTemp forKey:keyName];
                                
                                NSMutableArray *arrToppingOpt = [dicTemp valueForKey:@"LstProductVariantOptions"];
                                if(arrToppingOpt.count>0)
                                {
                                    NSMutableArray *toppingArr = [[NSMutableArray alloc] init];
                                    NSMutableArray *arrOfferIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
                                    if([arrOfferIndexes containsObject:[@(i) stringValue]])
                                    {
                                        int index = (int)[arrOfferIndexes indexOfObject:[@(i) stringValue]];
                                        NSMutableDictionary *obj = [selOfferToppings objectAtIndex:index ];
                                        
                                        NSLog(@"objVar: %@", obj);
                                        for(int k = 0; k < arrToppingOpt.count; k++)
                                        {
                                            NSString *key = [NSString stringWithFormat:@"ProductOptTopping%d%d", j, k];
                                            NSLog(@"%@",[obj valueForKey:key]);
                                            [toppingArr addObjectsFromArray:[obj valueForKey:key]];
                                        }
                                    }
                                    
                                    for(int k = 0; k < toppingArr.count; k++)
                                    {
                                        if([[toppingArr objectAtIndex:k] valueForKey:@"Price"] != (id)[NSNull null])
                                        {
                                            StandardOfferPrice = StandardOfferPrice+[[[toppingArr objectAtIndex:k] valueForKey:@"Price"] floatValue];
                                        }
                                        
                                    }
                                    
                                    NSString *keySubName = [@"ProductComponentsSubOptions" stringByAppendingString:itemNo];
                                    [tmpCartDict setObject:toppingArr forKey:keySubName];
                                    
                                }
                            }
                        }
                        else
                        {
                            for(int j = 0; j < tempArr.count; j++)
                            {
                                NSMutableDictionary *dicTemp = [tempArr objectAtIndex:j];
                                prodCompOptCount++;
                                NSString *itemNo = [@(prodCompOptCount) stringValue];
                                NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                                [tmpCartDict setObject:dicTemp forKey:keyName];
                                
                                NSMutableArray *arrToppingOpt = [dicTemp valueForKey:@"LstProductVariantOptions"];
                                if(arrToppingOpt.count>0)
                                {
                                    NSMutableArray *toppingArr = [[NSMutableArray alloc] init];
                                    NSMutableArray *arrOfferIndexes = [selOfferToppings valueForKey:@"SelOfferIndex"];
                                    if([arrOfferIndexes containsObject:[@(i) stringValue]])
                                    {
                                        int index = (int)[arrOfferIndexes indexOfObject:[@(i) stringValue]];
                                        NSMutableDictionary *obj = [selOfferToppings objectAtIndex:index ];
                                        
                                        NSLog(@"objVar: %@", obj);
                                        for(int k = 0; k < arrToppingOpt.count; k++)
                                        {
                                            NSString *key = [NSString stringWithFormat:@"ProductOptTopping%d%d", j, k];
                                            NSLog(@"%@",[obj valueForKey:key]);
                                            [toppingArr addObjectsFromArray:[obj valueForKey:key]];
                                        }
                                    }
                                    
                                    for(int k = 0; k < toppingArr.count; k++)
                                    {
                                        if([[toppingArr objectAtIndex:k] valueForKey:@"Price"] != (id)[NSNull null])
                                        {
                                            StandardOfferPrice = StandardOfferPrice+[[[toppingArr objectAtIndex:k] valueForKey:@"Price"] floatValue];
                                        }
                                        
                                    }
                                    
                                    NSString *keySubName = [@"ProductComponentsSubOptions" stringByAppendingString:itemNo];
                                    [tmpCartDict setObject:toppingArr forKey:keySubName];
                                    
                                }
                            }
                            /*
                            for(int j = 0; j < tempArr.count; j++)
                            {
                                NSMutableDictionary *dicTemp = [tempArr objectAtIndex:j];
                                prodCompOptCount++;
                                NSString *itemNo = [@(prodCompOptCount) stringValue];
                                NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                                [tmpCartDict setObject:dicTemp forKey:keyName];
                                
                                NSMutableArray *arrToppingOpt = [dicTemp valueForKey:@"LstProductVariantOptions"];
                                if(arrToppingOpt.count>0)
                                {
                                    NSMutableArray *toppingArr = [[NSMutableArray alloc] init];
                                    NSMutableArray *arrVarIndexes = [selOfferToppings valueForKey:@"SelVariantIndex"];
                                    if([arrVarIndexes containsObject:[@(j) stringValue]])
                                    {
                                        int index = (int)[arrVarIndexes indexOfObject:[@(j) stringValue]];
                                        NSMutableDictionary *obj = [selOfferToppings objectAtIndex:index ];
                                        
                                        NSLog(@"objVar: %@", obj);
                                        for(int k = 0; k < arrToppingOpt.count; k++)
                                        {
                                            NSString *key = [NSString stringWithFormat:@"ProductOptTopping%d%d", j, k];
                                            NSLog(@"%@",[obj valueForKey:key]);
                                            [toppingArr addObjectsFromArray:[obj valueForKey:key]];
                                        }
                                    }
                                    
                                    for(int k = 0; k < toppingArr.count; k++)
                                    {
                                        if([[toppingArr objectAtIndex:k] valueForKey:@"Price"] != (id)[NSNull null])
                                        {
                                            StandardOfferPrice = StandardOfferPrice+[[[toppingArr objectAtIndex:k] valueForKey:@"Price"] floatValue];
                                        }
                                        
                                    }
                                    
                                    NSString *keySubName = [@"ProductComponentsSubOptions" stringByAppendingString:itemNo];
                                    [tmpCartDict setObject:toppingArr forKey:keySubName];
                                    
                                }
                            }*/
                        }
                        
                    }
                    else
                    {
                        prodCompOptCount++;
                        NSString *itemNo = [@(prodCompOptCount) stringValue];
                        NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                        [tmpCartDict setObject:[selectedComponentPickerContent objectAtIndex:i] forKey:keyName];
                    }
                    
                }
                [tmpCartDict setObject:[@(prodCompOptCount+1) stringValue] forKey:@"ProductComponentsOptionsCount"];
                NSString *strStandardOfferPrice = [NSString stringWithFormat:@"%.02f",StandardOfferPrice];
                [tmpCartDict setObject:strStandardOfferPrice forKey:@"Price"];
                
            }
            if(!isError)
                selectedToppings = [[NSMutableArray alloc] init];
            
        }
        else
        {
            [tmpCartDict setObject:[dict valueForKey:@"Code"] forKey:@"Code"];
            [tmpCartDict setObject:[dict valueForKey:@"Description"] forKey:@"Description"];
            [tmpCartDict setObject:[dict valueForKey:@"DisplaySequence"] forKey:@"DisplaySequence"];
            [tmpCartDict setObject:[dict valueForKey:@"Name"] forKey:@"Name"];
            [tmpCartDict setObject:[dict valueForKey:@"ProductId"] forKey:@"ProductId"];
            
            [tmpCartDict setObject:[dict valueForKey:@"isCustomProduct"] forKey:@"isCustomProduct"];
            
            //Ashwani May 26, 2016:: Set here original price of product here
            if([dict valueForKey:@"Price"] != nil)
            {
                [tmpCartDict setObject:[dict valueForKey:@"Price"] forKey:@"OriginalPrice"];
            }
            else
            {
                [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] forKey:@"OriginalPrice"];
            }
            
            [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] forKey:@"Price"];
            [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Name"] forKey:@"ProductVariantName"];
            [tmpCartDict setObject:[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"ProductVariantId"] forKey:@"ProductVariantId"];
            
            float StandardOfferPrice = 0.0f;
            if([[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] != (id)[NSNull null])
                StandardOfferPrice = StandardOfferPrice+[[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"] floatValue];
            
            //Ashwani :: March 03, 2016 check here product varients topping is complsory or not
            NSMutableArray *arrVar = [dict valueForKey:@"ProductVariants"];
            for(int i = 0; i < arrVar.count; i++)
                {
                    
                    NSMutableArray *arrVarOpt = [[arrVar objectAtIndex:i ] valueForKey:@"ProductVariantOptions"];
                    for(int j = 0; j < arrVarOpt.count; j++)
                        {
                            if([[[arrVarOpt objectAtIndex:j]valueForKey:@"MinSelect"] integerValue]>0 && selectedToppings.count == 0)
                            {
                                isToppingError = YES;
                                break;
                            }
                        }
                }
            
            if(selectedprodOptionsPickerContent != nil && selectedprodOptionsPickerContent.count != 0)
            {
                //Ashwani :: Set here items in the same way as required in the xml
                
                [tmpCartDict setObject:[selectedprodOptionsPickerContent valueForKey:@"Name"]  forKey:@"ProductOptionName"];
                if([selectedprodOptionsPickerContent valueForKey:@"OptionItemId"] != (id)[NSNull null])
                    [tmpCartDict setObject:[selectedprodOptionsPickerContent valueForKey:@"OptionItemId"]  forKey:@"ProductOptionId"];
                else
                    [tmpCartDict setObject:[selectedprodOptionsPickerContent valueForKey:@"OptionId"]  forKey:@"ProductOptionId"];
            }
            else if(arrSelectedprodOptionsPickerContent.count>0)
            {
                
                [tmpCartDict setObject:[@(arrSelectedprodOptionsPickerContent.count) stringValue] forKey:@"ProductComponentsOptionsCount"];
                for(int i = 0; i < [arrSelectedprodOptionsPickerContent count]; i++)
                {
                    NSString *itemNo = [@(i) stringValue];
                    NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                    [tmpCartDict setObject:[arrSelectedprodOptionsPickerContent objectAtIndex:i] forKey:keyName];
                }
            }
            else if(selectedToppings.count > 0)
            {
                int k = 0;
                for(int i = 0; i < [selectedToppings count]; i++)
                {
                    NSMutableDictionary *dictData = [selectedToppings objectAtIndex:i];
                    if([[[dictData valueForKey:@"ProductVariantId"] stringValue] isEqualToString:[[selectedPickerContent valueForKey:@"ProductVariantId"] stringValue]])
                    {
                        NSMutableArray *subArr = [dictData valueForKey:@"ProductOptions"];
                        for(int j = 0; j < subArr.count; j++)
                        {
                            NSString *itemNo = [@(k) stringValue];
                            NSString *keyName = [@"ProductComponentsOptions" stringByAppendingString:itemNo];
                            [tmpCartDict setObject:[subArr objectAtIndex:j] forKey:keyName];
                            k++;
                            NSString *price = [[subArr objectAtIndex:j] valueForKey:@"Price"];
                            if(price != (id)[NSNull null])
                            {
                                if(price != nil && (![price isEqualToString:@""]))
                                    StandardOfferPrice = StandardOfferPrice+[price floatValue];
                                else
                                    StandardOfferPrice = StandardOfferPrice+0.00;
                            }
                        }
                    }
                }
                [tmpCartDict setObject:[@(k) stringValue] forKey:@"ProductComponentsOptionsCount"];
                //Ashwani :: Add price for other item here if exist
                NSString *strStandardOfferPrice = [NSString stringWithFormat:@"%.02f",StandardOfferPrice];
                [tmpCartDict setObject:strStandardOfferPrice forKey:@"Price"];
                /************************END******************************/
            }
            
            //Ashwani :: Oct 26.2015 empty the dictionary after use
            if(!isError)
            {
                selectedprodOptionsPickerContent = [[NSMutableDictionary alloc] init];
                arrSelectedprodOptionsPickerContent = [[NSMutableArray alloc] init];
                selectedToppings = [[NSMutableArray alloc] init];
            }
            
        }
    }
    
    //CHECK WHETHER ALL OPTIONS ARE SELECTED IN SET MEALS
    if (isError)
    {
        //[SVProgressHUD showErrorWithStatus:@"Select all options to add item into cart"];
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Message"
                                                     message:@"Select all options to add item into cart"
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil, nil];
        [al show];
        return;
    }
    //Ashwani March 03
    else if(isToppingError)
    {
        //[SVProgressHUD showErrorWithStatus:@"Select topping options from drop down to add item into cart"];
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Message"
                                                     message:@"Select topping options from drop down to add item into cart"
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil, nil];
        [al show];
        return;
    }
    else {
        
        NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
        tmpArr  = [[SharedContent sharedInstance] cartArr];
        [tmpArr addObject:tmpCartDict];
        
        [[SharedContent sharedInstance] setCartArr:tmpArr];
        [SVProgressHUD showSuccessWithStatus:@"Item added to cart"];
        if ([[dict valueForKey:@"ProductVariants"] count] > 1 || ([[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"CategoryName"] containsString:@"VOUJON"])) {
            [self.orderMenuTblView beginUpdates]; // tell the table you're about to start making changes
            expandedIndexPath = nil;
            [self.orderMenuTblView endUpdates];
            [self.orderMenuTblView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        //Ashwani :: Oct 30 2015 set table refresh once item selected
        else
        {
            [self.orderMenuTblView beginUpdates]; // tell the table you're about to start making changes
            expandedIndexPath = nil;
            [self.orderMenuTblView endUpdates];
            [self.orderMenuTblView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        //Ashwani :: ---------------------End here---------------------------//
        [self refreshFinalOrder];
    }
}

-(void)downButtonTapped:(id)sender{
    
    //Ashwani :: March 11, 2016
    selOfferVariants = [[NSMutableArray alloc] init];
    selOfferToppings = [[NSMutableArray alloc] init];
    compToppings = [[NSMutableDictionary alloc] init];
    
    //Ashwani :: Initialize here because each time table refresh and add duplicate data
    selectedComponentPickerContent = [[NSMutableArray alloc] init];
    
    //This array will store button index for each varient dropdown
    arrButtonTags = [[NSMutableArray alloc] init];
    
    //Ashwani :: Initialize arrayb to save topping here
    //This array will be use only in case of offers
    selectedToppings = [[NSMutableArray alloc] init];
    
    
    //Ashwani :: This array will be used to add mutiple option item
    arrSelectedprodOptionsPickerContent = [[NSMutableArray alloc] init];
    
    //Initialize array here to selected items
    arraySelect = [[NSMutableArray alloc] init];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([sender tag]%1000) inSection:([sender tag]/1000)];
    
    if (![indexPath compare:expandedIndexPath] == NSOrderedSame) {
        expandedIndexPath = nil;
        [self.orderMenuTblView reloadData];
    }

    [self.orderMenuTblView beginUpdates]; // tell the table you're about to start making changes
    
    if ([indexPath compare:expandedIndexPath] == NSOrderedSame) {
        expandedIndexPath = nil;
        //selectedPickerContent = [[NSMutableDictionary alloc] init];
    } else {
        expandedIndexPath = indexPath;
    }
    
    [self.orderMenuTblView endUpdates];
    
    [self.orderMenuTblView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

- (void) refreshFinalOrder {
    
    double price = 0.0;
    
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    tmpArr  = [[[SharedContent sharedInstance] cartArr] valueForKey:@"Price"];
    
    for (int i = 0; i < tmpArr.count; i++) {
        
        price = price + [[tmpArr objectAtIndex:i] doubleValue];
    }
    
    if (price>0.0) {
        [self.checkoutButton setHidden:false];
        self.orderPriceLbl.text = [NSString stringWithFormat:@"Order £%.2f",price];
    }
    else {
        [self.checkoutButton setHidden:true];
        self.orderPriceLbl.text = [NSString stringWithFormat:@"Order £0.00"];
    }

    
}


-(void)ProductbtnTapped_old:(id)sender
{
    selectedItems = [[NSMutableArray alloc] init];
    selectedComponentID = @"";
    int selctedTag = (int)[sender tag]-2000;
    
    NSArray *arr = [[NSArray alloc] init];
    arr = [arraySelect valueForKey:@"ComponentId"];
    
    //[NSArray arrayWithObject:[arraySelect valueForKey:@"ComponentId"]];
    
    int indexValue = (int)[arr indexOfObject:@(selctedTag)];
    
    maxselect = [[[arraySelect objectAtIndex:indexValue] valueForKey:@"MaxSelect"] intValue];
    minselect = [[[arraySelect objectAtIndex:indexValue] valueForKey:@"MinSelect"] intValue];
    
    //Ashwani :: Check price here for offers, if zero then use absolute or relative price in create picker view
    AbsolutePrice = @"";
    RelativePrice = @"";
    IsOfferPriceZero = FALSE;
    if([[[arraySelect objectAtIndex:indexValue] valueForKey:@"offerPrice"] isEqualToString:@"0.00"])
    {
        IsOfferPriceZero = TRUE;
        
        NSString *absolutePrice;
        NSString *relativePrice;
        if([[arraySelect objectAtIndex:indexValue] valueForKey:@"PriceAbsolute"] != (id)[NSNull null])
            absolutePrice = [[[arraySelect objectAtIndex:indexValue] valueForKey:@"PriceAbsolute"] stringValue];
        else
            absolutePrice = [[arraySelect objectAtIndex:indexValue] valueForKey:@"PriceAbsolute"];
        
        if([[arraySelect objectAtIndex:indexValue] valueForKey:@"PriceRelative"] != (id)[NSNull null])
            relativePrice = [[[arraySelect objectAtIndex:indexValue] valueForKey:@"PriceRelative"] stringValue];
        else
            relativePrice = [[arraySelect objectAtIndex:indexValue] valueForKey:@"PriceRelative"];
        
        if(absolutePrice != nil && absolutePrice != (id)[NSNull null])
        {
            AbsolutePrice = absolutePrice;
        }
        else if(relativePrice != nil && relativePrice != (id)[NSNull null])
        {
            RelativePrice = relativePrice;
        }
    }
    // picker1.hidden = FALSE;
}


#pragma mark - Custom Option Picker button Tapped -
-(void)ProductbtnTapped:(id)sender
{
    [viewHeader removeFromSuperview];
    
    //Ashwani :: THis check will use to verify that custom item is already selected or not
    IsItemSelectionAllow = TRUE;
    
    
    //Ashwani :: Oct 30, 2015 set user interaction disabled for orderMenuTblView
    self.orderMenuTblView.userInteractionEnabled = FALSE;
    
    //Ashwani :: Nov 03, 2015 Initialize topping array here bcos item will be added to it when selected from options with toppings
    arrToppings = [[NSMutableArray alloc] init];
    selectedItems = [[NSMutableArray alloc] init];
    selectedComponentID = @"";
    
    SelOfferIndex = (int)[sender tag]-2000;
    
    selVariants = [[NSMutableArray alloc] init];
    //Ashwani :: Set here offer if already selected
    if([[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] allKeys] containsObject:@"ProductComponents"])
    {
        selVariants = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"ProductComponents"];
    }
    
    [self CreatePickerView];
}

-(void)CreatePickerView
{
    maxselect = [[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"MaxSelect"] intValue];
    //Ashwani :: Check for sauces if number of chutneies are less than min select
    if([[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"DisplayName"] isEqualToString:@"Chutnies"])
    {
        minselect = 0;
    }
    else
        minselect = [[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"MinSelect"] intValue];
    
    //Ashwani :: Check price here for offers, if zero then use absolute or relative price in create picker view
    AbsolutePrice = @"";
    RelativePrice = @"";
    IsOfferPriceZero = FALSE;
    if([[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"offerPrice"] isEqualToString:@"0.00"])
    {
        IsOfferPriceZero = TRUE;
        NSString *absolutePrice;
        NSString *relativePrice;
        if([[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"PriceAbsolute"] != (id)[NSNull null])
            absolutePrice = [[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"PriceAbsolute"] stringValue];
        else
            absolutePrice = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"PriceAbsolute"];
        
        if([[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"PriceRelative"] != (id)[NSNull null])
            relativePrice = [[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"PriceRelative"] stringValue];
        else
            relativePrice = [[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"PriceRelative"];
        
        if(absolutePrice != nil && absolutePrice != (id)[NSNull null])
        {
            AbsolutePrice = absolutePrice;
        }
        else if(relativePrice != nil && relativePrice != (id)[NSNull null])
        {
            RelativePrice = relativePrice;
        }
    }
    
    NSString *componentID = [[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"ComponentId"] stringValue];
    if(![componentID isEqualToString:selectedComponentID]){
        selectedComponentID = componentID;
    }
    
    //Ashwani :: clear selected item array each time
    selectedItems = [[NSMutableArray alloc] init];
    
    //Ashwani :: Select prodcomponent id for comapre it on selection
    NSString *prodComponentID = [[[selectedComponentPickerContent objectAtIndex:SelOfferIndex] valueForKey:@"ProductComponentId"] stringValue];
    if(![prodComponentID isEqualToString:selectedProdCompID]){
        selectedProdCompID = prodComponentID;
    }
    
    [viewHeader removeFromSuperview];
    
    selctedArrItems = [[NSMutableArray alloc] init];
    NSMutableArray *tempComponentItemArr = [[NSMutableArray alloc] init];
    tempComponentItemArr = componentItemArr;
    for(int i = 0 ; i < [componentItemArr count]; i++)
    {
        if([[[[componentItemArr objectAtIndex:i] valueForKey:@"ComponentId"] stringValue] isEqualToString:componentID])
        {
            //Ashwani Oct28,2015 :: Set here price for items if Offers available is buy one get one free
            if(![AbsolutePrice isEqualToString:@""])
            {
                NSMutableArray *tempArr = [[tempComponentItemArr objectAtIndex:i] valueForKey:@"Variants"];
                
                NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                tempDict = [[tempArr objectAtIndex:0] mutableCopy];
                [tempDict setValue:AbsolutePrice forKey:@"Price"];
                
                //NSMutableArray *tempArr1 = [[NSMutableArray alloc] init];
                //[tempArr1 addObject:tempDict];
                [selctedArrItems addObject:tempDict];
            }
            else if(![RelativePrice isEqualToString:@""])
            {
                NSMutableArray *tempArr = [[tempComponentItemArr objectAtIndex:i] valueForKey:@"Variants"];
                NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
                tempDict = [[tempArr objectAtIndex:0] mutableCopy];
                
                float relPrice = [RelativePrice floatValue];
                NSString *strItemPrice = [tempDict  valueForKey:@"Price"];
                float itemPrice = [strItemPrice floatValue];
                float afterDiscountprice = 0.00f;
                afterDiscountprice = relPrice * itemPrice;
                NSString *overallPrice = [NSString stringWithFormat:@"%.02f",afterDiscountprice];
                [tempDict setValue:overallPrice forKey:@"Price"];
                //NSMutableArray *tempArr1 = [[NSMutableArray alloc] init];
                //[tempArr1 addObject:tempDict];
                [selctedArrItems addObject:tempDict];
            }
            else
            {
                NSMutableArray *tempArr1 = [[tempComponentItemArr objectAtIndex:i] valueForKey:@"Variants"];
                [selctedArrItems addObject:[tempArr1 objectAtIndex:0]];
            }
        }
    }
    int height = [[UIScreen mainScreen] bounds].size.height;
    int width = [[UIScreen mainScreen] bounds].size.width;
    
    //Ashwani :: Oct 20 2015 Check here forthe item are multiple selection or not
    viewHeader = [[UIView alloc] initWithFrame:CGRectMake(0, height-270, width, 270)];
    viewHeader.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:viewHeader];
    
    tableViewPicker = [[UITableView alloc] initWithFrame:CGRectMake(0, 35, width, viewHeader.frame.size.height- 35) style:UITableViewStylePlain];
    tableViewPicker.dataSource = self;
    tableViewPicker.delegate = self;
    tableViewPicker.tag = SelOfferIndex;
    [tableViewPicker setBackgroundColor:[UIColor whiteColor]];
    [viewHeader addSubview:tableViewPicker];
    
    componentPickerDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    componentPickerDoneButton.frame = CGRectMake(width-65, 0, 60, 30);
    [componentPickerDoneButton addTarget:self action:@selector(DoneButtonTappedCustom:) forControlEvents:UIControlEventTouchUpInside];
    componentPickerDoneButton.showsTouchWhenHighlighted = YES;
    [componentPickerDoneButton setTitle:@"Done" forState:UIControlStateNormal];
    [viewHeader addSubview:componentPickerDoneButton];
    
    
}


#pragma mark - TABLE VIEW

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == self.menuTableView)
        return 1;
    else if(tableView == tableViewPicker)
        return 1;
    else if(tableView == tableViewOptPicker)
        return 1;
    else if(tableView == tblToppingPicker)
        return 1;
    else if(tableView == tblToppingPickerForStandard)
        return 1;
    else if(tableView == tblOfferVarients)
        return 1;
    else
        return [menuDisplayArr count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if(tableView == self.menuTableView)
        return 50;
    else if(tableView == tableViewPicker)
        return 40;
    else if(tableView == tableViewOptPicker)
        return 40;
    else if(tableView == tblToppingPicker)
        return 40;
    else if(tableView == tblOfferVarients)
        return 40;
    else if(tableView == tblToppingPickerForStandard)
        return 40;
    else
    {
        if ([indexPath compare:expandedIndexPath] == NSOrderedSame) {
            
            NSMutableDictionary *dict = [[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"Products"] objectAtIndex:indexPath.row];
            if(dict == nil){
                
                NSMutableDictionary *dict = [[[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"CustomProducts"] objectAtIndex:indexPath.row] valueForKey:@"ProductComponents"];
                
                isSetMealView = TRUE;
                return [dict count]*40+250;
                
            }
            else{
                isSetMealView = FALSE;
                return 280.0; // Expanded height
            }
        }
        isSetMealView = FALSE;
        return 120;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if(tableView == self.menuTableView)
        return ([categoryArr count]+1);
    
    else if(tableView == tableViewPicker){
        txtTag = (int)(tableView.tag)+2000;
        return [selctedArrItems count];
    }
    else if(tableView == tableViewOptPicker){
        txtTag = (int)(tableView.tag)+10000;
        return [pickerOptArr count];
        
    }
    else if(tableView == tblToppingPicker){
        
        toppingTag = (int)(tableView.tag);
        
        
        //toppingTag = (int)(tableView.tag)+40000;//+20000;
        return [toppingPickerOptionArray count];
    }
    else if(tableView == tblToppingPickerForStandard){
        toppingTag = (int)(tableView.tag)+20000;
        return [toppingPickerOptionArray count];
    }
    else if(tableView == tblOfferVarients){
        //toppingTag = (int)(tableView.tag)+20000;
        return [selVariants count];
    }
    else
    {
        //Aswani :: Check here for products of custom products for number of rows
        if([[[menuDisplayArr objectAtIndex:section] valueForKey:@"Products"] count] != 0)
            return [[[menuDisplayArr objectAtIndex:section] valueForKey:@"Products"] count];
        else
            return [[[menuDisplayArr objectAtIndex:section] valueForKey:@"CustomProducts"] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == self.menuTableView)
    {
        LMMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"menuCell"];
        if (!cell) {
            cell = [[LMMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"menuCell"];
        }
        
        if (indexPath.row==0) {
            cell.menuItemLabel.text = @"All";
        }
        else {
          
            cell.menuItemLabel.text = [[categoryArr objectAtIndex:(indexPath.row-1)] valueForKey:@"CategoryName"];
        }
        
        cell.selectedMarkView.hidden = (indexPath.row != self.currentMapTypeIndex);
        return cell;
    }
    else if(tableView == tblOfferVarients)
    {
        static NSString *CellIdentifier = @"newCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        NSString * str = [[selVariants objectAtIndex:indexPath.row] valueForKey:@"DisplayName"];
        [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        NSMutableArray *arrOfferIndex = [selOfferToppings valueForKey:@"SelOfferIndex"];
        if([arrOfferIndex containsObject:[@(SelOfferIndex) stringValue]])
        {
            NSMutableArray *arrVarIndex = [selOfferToppings valueForKey:@"SelVariantIndex"];
            if([arrVarIndex containsObject:[@(indexPath.row) stringValue]])
            {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            else
            {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
                
            }
        }
        else
        {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            
        }
    
        if(indexPath.row == SelVariantIndex)
        {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else if(tableView == tblToppingPicker)
    {
        static NSString *CellIdentifier = @"newCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        //if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        //}
        
        NSString * str = [[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"Name"];
        
        UILabel *lblText = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, cell.frame.size.width-110, cell.frame.size.height)];
        [lblText setText:[str stringByAppendingString:@" (£0)"]];
        lblText.font = [UIFont systemFontOfSize:12.0f];
        lblText.frame = CGRectMake(0, 0, cell.frame.size.width-110, cell.frame.size.height);
        lblText.numberOfLines = 2;
        [cell.contentView addSubview:lblText];
        
        //Ashwnai :: Add price with item name
        NSString *strPrice = [[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"Price"];
        if(strPrice != (id)[NSNull null])
        {
            if(strPrice != nil && (![strPrice isEqualToString:@""]))
                [lblText setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
            else
                [lblText setText:[str stringByAppendingString:@" (£0)"]];
        }
        else
            [lblText setText:[str stringByAppendingString:@" (£0)"]];
        
        //Ashwnai :: Add price with item name
//        NSString *strPrice = [[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"Price"];
//        if(strPrice != (id)[NSNull null])
//        {
//            if(strPrice != nil && (![strPrice isEqualToString:@""]))
//                [cell.textLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
//            else
//                [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
//        }
//        else
//            [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
//        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
//        cell.textLabel.frame = CGRectMake(0, 0, cell.frame.size.width-110, cell.frame.size.height);
//        cell.textLabel.numberOfLines = 2;
//        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        //****************************************************************
//        NSMutableArray *optionItemIdArr = [selToppings valueForKey:@"OptionItemId"];
//        
//        if([optionItemIdArr containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionItemId"]])
//            {
//                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
//            }
//            else
//            {
//                [cell setAccessoryType:UITableViewCellAccessoryNone];
//            }
        
        //Ashwani :: March 08, 2016
        UIButton *btnMinus = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width-100, 5, 30, 30)];
        //[btnMinus setImage:[UIImage imageNamed:@"ic_minus.png"] forState:UIControlStateNormal];
        [btnMinus setImage:[UIImage imageNamed:@"minus.png"] forState:UIControlStateNormal];
        [btnMinus addTarget:self action:@selector(DeleteToppings:) forControlEvents:UIControlEventTouchUpInside];
        btnMinus.tag = indexPath.row;
        [cell.contentView addSubview:btnMinus];
        
        lblOfferCount = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width-65, 10, 20, 20)];
        //lblOfferCount.text = @"0";
        lblOfferCount.tag = indexPath.row;
        lblOfferCount.layer.borderColor = [UIColor lightGrayColor].CGColor;
        lblOfferCount.layer.borderWidth = 1.0f;
        lblOfferCount.font = [UIFont systemFontOfSize:12.0f];
        lblOfferCount.textAlignment = NSTextAlignmentCenter;
        lblOfferCount.layer.cornerRadius = 4.0f;
        [cell.contentView addSubview:lblOfferCount];
        
        UIButton *btnAdd = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width-40, 5, 30, 30)];
        //[btnAdd setImage:[UIImage imageNamed:@"ic_add_48pt.png"] forState:UIControlStateNormal];
        [btnAdd setImage:[UIImage imageNamed:@"plus.png"] forState:UIControlStateNormal];
        [btnAdd addTarget:self action:@selector(AddToppings:) forControlEvents:UIControlEventTouchUpInside];
        btnAdd.tag = indexPath.row;
        [cell.contentView addSubview:btnAdd];
        
        int count = 0;
        lblOfferCount.text = [@(count) stringValue];
        if(selToppings.count>0)
        {
            //NSMutableArray *ComponentIdArr = [selVariants valueForKey:@"ComponentId"];
            for(int i = 0; i < selToppings.count; i++)
            {
                
                if([[[selToppings objectAtIndex:i] valueForKey:@"OptionItemId"] isEqual:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionItemId"]] && [[[selToppings objectAtIndex:i] valueForKey:@"ProductVariantId"] isEqual:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"ProductVariantId"]])
                {
                    count++;
                }
            }
            
            //            for(int i = 0; i < selVariants.count; i++)
            //            {
            //                if([[[selVariants objectAtIndex:i] valueForKey:@"ComponentId"] isEqual:[[selctedArrItems objectAtIndex:indexPath.row] valueForKey:@"ComponentId"]])
            //                {
            //                    count++;
            //
            //                }
            //            }
            lblOfferCount.text = [@(count) stringValue];
        }
        
        
        
        
        str = @"";
        for(int i = 0; i < [selToppings count]; i++)
        {
            if(i > 0)
                str = [str stringByAppendingFormat:@" & %@ ",[[selToppings objectAtIndex:i] valueForKey:@"Name"]];
            else
                str = [NSString stringWithFormat:@"%@ ",[[selToppings objectAtIndex:i] valueForKey:@"Name"]];
        }
        UIButton *btn = (UIButton *)[customView2 viewWithTag:toppingTag];
        if(str != nil || (![str isEqualToString:@""]))
            [btn setTitle:str forState:UIControlStateNormal];
        
        //**************************************************************
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else if(tableView == tblToppingPickerForStandard)
    {
        static NSString *CellIdentifier = @"newCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        //NSMutableArray *arr = [[NSMutableArray alloc] init];
        //arr = [pickerOptArr objectAtIndex:indexPath.row];
        NSString * str = [[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"Name"];
        
        //Ashwnai :: Add price with item name
        NSString *strPrice = [[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"Price"];
        if(strPrice != (id)[NSNull null])
        {
            if(strPrice != nil && (![strPrice isEqualToString:@""]))
                [cell.textLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
            else
                [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
        }
        else
            [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
        
        
        
        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        //****************************************************************
        NSMutableArray *selectedProdVarId = [selectedToppings valueForKey:@"ProductVariantId"];
        NSMutableArray *selectedOptionId = [selectedToppings valueForKey:@"OptionId"];
        if([selectedProdVarId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"ProductVariantId"]] && [selectedOptionId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionId"]])
        {
            
            //int indexOfProdVarID = (int)[selectedOptionId indexOfObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"ProductVariantId"]];
            // NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            // dict = [selectedToppings objectAtIndex:indexOfProdVarID];
            
            int index = (int)[selectedOptionId indexOfObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionId"]];
            NSMutableArray *tempArr = [[selectedToppings objectAtIndex:index] valueForKey:@"ProductOptions"];
            
            NSMutableArray *arrOptionItemId = [tempArr valueForKey:@"OptionItemId"];
            if([arrOptionItemId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionItemId"]])
            {
                [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            }
            else
            {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
                
            }
        }
        else
        {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            
        }
        
        
        //Ashwani ":: set the selected text on button from heer
        str = @"";
        if([selectedProdVarId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"ProductVariantId"]] && [selectedOptionId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionId"]])
        {
            int index = (int)[selectedOptionId indexOfObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionId"]];
            NSMutableArray *tempArr = [[selectedToppings objectAtIndex:index] valueForKey:@"ProductOptions"];
            
            NSMutableArray *arrOptionItemId = [tempArr valueForKey:@"OptionItemId"];
            if([arrOptionItemId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionItemId"]])
            {
                for(int i = 0; i < [tempArr count]; i++)
                {
                    if(i > 0)
                        str = [str stringByAppendingFormat:@" & %@ ",[[tempArr objectAtIndex:i] valueForKey:@"Name"]];
                    else
                        str = [NSString stringWithFormat:@"%@ ",[[tempArr objectAtIndex:i] valueForKey:@"Name"]];
                }
            }
        }
        
        
        UIButton *btn = (UIButton *)[customView2 viewWithTag:toppingTag];
        if(str != nil && (![str isEqualToString:@""]))
            [btn setTitle:str forState:UIControlStateNormal];
        
        
        //**************************************************************
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else if(tableView == tableViewPicker)
    {
        static NSString *CellIdentifier = @"newCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        //if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        //}
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSString * str = [[selctedArrItems objectAtIndex:indexPath.row] valueForKey:@"DisplayName"];
        //Ashwnai :: Add price with item name
        if(IsOfferPriceZero)
        {
            NSString *strPrice = [[selctedArrItems objectAtIndex:indexPath.row] valueForKey:@"Price"];
            if(strPrice != nil && (![strPrice isEqualToString:@""]))
                [cell.textLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
            else
                [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
        }
        else
            [cell.textLabel setText:[str stringByAppendingString:@""]];
        
        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        //Ashwani :: March 08, 2016
        UIButton *btnMinus = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width-100, 5, 30, 30)];
        //[btnMinus setImage:[UIImage imageNamed:@"ic_minus.png"] forState:UIControlStateNormal];
        [btnMinus setImage:[UIImage imageNamed:@"minus.png"] forState:UIControlStateNormal];
        [btnMinus addTarget:self action:@selector(DeleteOffer:) forControlEvents:UIControlEventTouchUpInside];
        btnMinus.tag = indexPath.row;
        [cell.contentView addSubview:btnMinus];
        
        lblOfferCount = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width-65, 10, 20, 20)];
        //lblOfferCount.text = @"0";
        lblOfferCount.tag = indexPath.row;
        lblOfferCount.layer.borderColor = [UIColor lightGrayColor].CGColor;
        lblOfferCount.layer.borderWidth = 1.0f;
        lblOfferCount.font = [UIFont systemFontOfSize:12.0f];
        lblOfferCount.textAlignment = NSTextAlignmentCenter;
        lblOfferCount.layer.cornerRadius = 4.0f;
        [cell.contentView addSubview:lblOfferCount];
        
        UIButton *btnAdd = [[UIButton alloc] initWithFrame:CGRectMake(cell.frame.size.width-40, 5, 30, 30)];
        //[btnAdd setImage:[UIImage imageNamed:@"ic_add_48pt.png"] forState:UIControlStateNormal];
        [btnAdd setImage:[UIImage imageNamed:@"plus.png"] forState:UIControlStateNormal];
        [btnAdd addTarget:self action:@selector(AddOffer:) forControlEvents:UIControlEventTouchUpInside];
        btnAdd.tag = indexPath.row;
        [cell.contentView addSubview:btnAdd];
        
        int count = 0;
        lblOfferCount.text = [@(count) stringValue];
        if(selVariants.count>0)
        {
            //NSMutableArray *ComponentIdArr = [selVariants valueForKey:@"ComponentId"];
            for(int i = 0; i < selVariants.count; i++)
            {
                
                if([[[selVariants objectAtIndex:i] valueForKey:@"ComponentId"] isEqual:[[selctedArrItems objectAtIndex:indexPath.row] valueForKey:@"ComponentId"]] && [[[selVariants objectAtIndex:i] valueForKey:@"ProductVariantId"] isEqual:[[selctedArrItems objectAtIndex:indexPath.row] valueForKey:@"ProductVariantId"]])
                {
                    count++;
                }
            }
            
//            for(int i = 0; i < selVariants.count; i++)
//            {
//                if([[[selVariants objectAtIndex:i] valueForKey:@"ComponentId"] isEqual:[[selctedArrItems objectAtIndex:indexPath.row] valueForKey:@"ComponentId"]])
//                {
//                    count++;
//                
//                }
//            }
            lblOfferCount.text = [@(count) stringValue];
        }
        
        

//        if(IsItemSelectionAllow)
//        {
//            NSMutableArray *arrCompId = [selectedComponentPickerContent valueForKey:@"ProductVariantId"];
//            if([arrCompId containsObject:[[arr objectAtIndex:0] valueForKey:@"ProductVariantId"]])
//            {
//                [selectedItems addObject:indexPath];
//                //Ashwani :: March 03, 2016 If Toppings are already selected then add selected data
//                [arrToppings addObject:[selctedArrItems objectAtIndex:indexPath.row]];
//            }
//        }
        
//        if ([selectedItems containsObject:indexPath]) {
//            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
//        }
//        else
//        {
//            [cell setAccessoryType:UITableViewCellAccessoryNone];
//        }
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else if(tableView == tableViewOptPicker)
    {
        static NSString *CellIdentifier = @"newCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        NSString * str = [[pickerOptArr objectAtIndex:indexPath.row] valueForKey:@"Name"];
        
        //Ashwnai :: Add price with item name
        NSString *strPrice = [[pickerOptArr objectAtIndex:indexPath.row] valueForKey:@"Price"];
        if(strPrice != (id)[NSNull null])
        {
            if(strPrice != nil && (![strPrice isEqualToString:@""]))
                [cell.textLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
            else
                [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
        }
        else
            [cell.textLabel setText:[str stringByAppendingString:@" (£0)"]];
        
        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        
        selectedOptItems = arrSelectedprodOptionsPickerContent;
        NSMutableArray *arrOptionItemId = [selectedOptItems valueForKey:@"OptionItemId"];
        if([arrOptionItemId containsObject:[[pickerOptArr objectAtIndex:indexPath.row] valueForKey:@"OptionItemId"]])
        {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        else
        {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            
        }
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else
    {
        NSString* identifier = @"customListingCell";
        ListingCustomTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ListingCustomTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        
        NSMutableDictionary *dict = [[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"Products"] objectAtIndex:indexPath.row];
        if(dict != nil)
        {
            cell.ItemTitle.text = [dict valueForKey:@"Name"];
            cell.ItemTitle.adjustsFontSizeToFitWidth = TRUE;
            
            cell.ItemDescription.text = [[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"CategoryName"];
            cell.ItemPrice.text = [NSString stringWithFormat:@"£%@",[[[dict valueForKey:@"ProductVariants"] objectAtIndex:0] valueForKey:@"Price"]];
            
            if([cell.ItemTitle.text isEqualToString:cell.ItemDescription.text])
            {
                cell.ItemDescription.text = @"";
            }

            if (![[dict valueForKey:@"Description"] isEqual:[NSNull null]]) {
                cell.ItemOther.text = [dict valueForKey:@"Description"];
            }
            else {
                cell.ItemOther.text = @"";
            }
        
                if ([indexPath compare:expandedIndexPath] == NSOrderedSame)
                {
                [cell.addArrowButton setImage:[UIImage imageNamed:@"ic_keyboard_arrow_up_48pt.png"] forState:UIControlStateNormal];
                [cell.addArrowButton removeTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [cell.addArrowButton addTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [cell.variantLbl setHidden:false];
                [cell.variantTxtField setHidden:false];
                [cell.optionAddButton setHidden:false];
                [cell.optionsPriceLbl setHidden:false];
                [cell.includingOptionsLbl setHidden:false];
            
                variantArr = [[NSMutableArray alloc] init];
            
                if ([[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"CategoryName"] containsString:@"VOUJON"]) {           //Spices - Voujon Dishes
                
                    NSMutableArray *arr  =  [dict valueForKey:@"ProductVariants"];
                    //[cell.optionsPriceLbl setHidden:true];
                    NSString *strOptionId = [[arr objectAtIndex:0] valueForKey:@"OptionId"];
                    
                    //[[taglistDict allKeys]containsObject:key]
                    if([[[arr objectAtIndex:0] allKeys] containsObject:@"OptionId"])
                    {
                        if([[arr objectAtIndex:0] valueForKey:@"OptionId"] != (id)[NSNull null] || [[arr objectAtIndex:0] valueForKey:@"OptionId"] != nil)
                        {
                            selectedStrengthPickerContent = [prodOptionsArr objectAtIndex: 0];
                            if([[[selectedStrengthPickerContent valueForKey:@"OptionId"] stringValue] isEqualToString:@"1"])
                            {
                                cell.variantTxtField.text = [[prodOptionsArr objectAtIndex:0] valueForKey:@"Name"];
                                [cell.variantLbl setText:@"Sauces"];
                                for(int i = 0 ; i < [prodOptionsItemArr count]; i++)
                                {
                                    if([[[[prodOptionsItemArr objectAtIndex:i] valueForKey:@"OptionId"] stringValue] isEqualToString:@"1"])
                                    {
                                        [variantArr addObject:[prodOptionsItemArr objectAtIndex:i]];
                                    }
                                }
                            }
                            else
                            {
                                [cell.variantLbl setText:@"Strength"];
                                cell.variantTxtField.text = [[prodOptionsArr objectAtIndex:1] valueForKey:@"Name"];
                                for(int i = 0 ; i < [prodOptionsItemArr count]; i++)
                                {
                                    if([[[[prodOptionsItemArr objectAtIndex:i] valueForKey:@"OptionId"] stringValue] isEqualToString:@"2"])
                                    {
                                        [variantArr addObject:[prodOptionsItemArr objectAtIndex:i]];
                                    }
                                }
                            }
                            
                            
                    }
                    
                        strengthPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 480, 320, 270)];
                        strengthPicker.delegate = self;
                        strengthPicker.dataSource = self;
                        strengthPicker.showsSelectionIndicator = YES;
                        
                        UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
                        [toolBar setBarStyle:UIBarStyleBlackOpaque];
                        UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
                        customButton.frame = CGRectMake(0, 0, 60, 33);
                        [customButton addTarget:self action:@selector(strengthPickerViewDoneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                        customButton.showsTouchWhenHighlighted = YES;
                        [customButton setTitle:@"Done" forState:UIControlStateNormal];
                        UIBarButtonItem *barCustomButton =[[UIBarButtonItem alloc] initWithCustomView:customButton];
                        UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                        toolBar.items = [[NSArray alloc] initWithObjects:flexibleSpace,barCustomButton,nil];
                        cell.variantTxtField.inputView = strengthPicker;
                        cell.variantTxtField.inputAccessoryView = toolBar;
                        
                        //Ashwani :: March 03 2016 Drop Down Icon
                        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.variantTxtField.frame.size.width-30, 0, 30, 30)];
                        imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
                        [cell.variantTxtField addSubview:imgView];
                   // }
                    //[picker addSubview:toolBar];
                    }
                    
                    else //SHOW NORMAL VARIANTS IF OPTION ID IS NULL
                        {
                            
                            //***************************
                            variantArr = [dict valueForKey:@"ProductVariants"];
                            selectedPickerContent = [variantArr objectAtIndex: 0];
                            
                            NSString * str = [selectedPickerContent valueForKey:@"DisplayName"];
                            cell.variantTxtField.text = str;
                            //cell.variantTxtField.text = @"Please select an item";
                            //cell.variantTxtField.
                            strOptionSelected = @"Please select an item";
                            picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 480, 320, 270)];
                            picker.delegate = self;
                            picker.dataSource = self;
                            picker.showsSelectionIndicator = YES;
                            
                            UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
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
                            
                            //Ashwani :: Set editable false
                            if([variantArr count]>1)
                            {
                                cell.variantTxtField.inputView = picker;
                                //Ashwani :: March 03 2016 Drop Down Icon
                                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.variantTxtField.frame.size.width-30, 0, 30, 30)];
                                imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
                                [cell.variantTxtField addSubview:imgView];
                            }
                            else
                            {
                                NSMutableArray *arr = [[NSMutableArray alloc] init];
                                arr = [[variantArr objectAtIndex:0] valueForKey:@"ProductVariantOptions"];
                                if(arr.count > 0)
                                {
                                    //Ashwani :: March 03 2016 Drop Down Icon
                                    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.variantTxtField.frame.size.width-30, 0, 30, 30)];
                                    imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
                                    [cell.variantTxtField addSubview:imgView];
                                    cell.variantTxtField.inputView = picker;
                                }
                                else
                                {
                                    cell.variantTxtField.text = [[variantArr objectAtIndex:0]valueForKey:@"DisplayName"];
                                    cell.variantTxtField.userInteractionEnabled = FALSE;
                                }
                            }
                            
                            cell.variantTxtField.inputAccessoryView = toolBar;
                            cell.variantTxtField.delegate = self;
                            cell.optionsPriceLbl.text = [NSString stringWithFormat:@"£%@",[selectedPickerContent valueForKey:@"Price"]];
                    }
                    
                    cell.variantTxtField.delegate = self;
                    cell.optionsPriceLbl.text = cell.ItemPrice.text;
            
                }
                else {
                
                    //***************************
                    variantArr = [dict valueForKey:@"ProductVariants"];
                    selectedPickerContent = [variantArr objectAtIndex: 0];
                
                    NSString * str = [selectedPickerContent valueForKey:@"DisplayName"];
                    cell.variantTxtField.text = str;
                    //cell.variantTxtField.text = @"Please select an item";
                    //cell.variantTxtField.
                    strOptionSelected = @"Please select an item";
                    picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 480, 320, 270)];
                    picker.delegate = self;
                    picker.dataSource = self;
                    picker.showsSelectionIndicator = YES;
                
                    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
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
                    
                    //Ashwani :: Set editable false
                    if(variantArr.count>0)
                    {
                        if([variantArr count]>1)
                        {
                            cell.variantTxtField.inputView = picker;
                            //Ashwani :: March 03 2016 Drop Down Icon
                            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.variantTxtField.frame.size.width-30,0 , 30, 30)];
                            imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
                            [cell.variantTxtField addSubview:imgView];
                        }
                        else
                        {
                            NSMutableArray *arr = [[NSMutableArray alloc] init];
                            arr = [[variantArr objectAtIndex:0] valueForKey:@"ProductVariantOptions"];
                            if(arr.count > 0)
                            {
                                //Ashwani :: March 03 2016 Drop Down Icon
                                UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.variantTxtField.frame.size.width-30, 0, 30, 30)];
                                imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
                                [cell.variantTxtField addSubview:imgView];
                                cell.variantTxtField.inputView = picker;
                            }
                            else
                            {
                                cell.variantTxtField.text = [[variantArr objectAtIndex:0]valueForKey:@"DisplayName"];
                                cell.variantTxtField.userInteractionEnabled = FALSE;
                            }
                        }
                    }
                    
                    cell.variantTxtField.inputAccessoryView = toolBar;
                    cell.variantTxtField.delegate = self;
                    cell.optionsPriceLbl.text = [NSString stringWithFormat:@"£%@",[selectedPickerContent valueForKey:@"Price"]];
                    }
            
            
                    [cell.optionAddButton removeTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [cell.optionAddButton addTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            
                cell.optionAddButton.tag = (indexPath.section * 1000) + indexPath.row;
            }
                else {
            
                [cell.variantLbl setHidden:true];
                [cell.variantTxtField setHidden:true];
                [cell.optionAddButton setHidden:true];
                [cell.optionsPriceLbl setHidden:true];
                [cell.includingOptionsLbl setHidden:true];
            
                    
                //Ashwnai :: Check here for souces if exist
                NSMutableArray *arrOptionsProd = [dict valueForKey:@"ProductVariants"];

                if ([[dict valueForKey:@"ProductVariants"] count] > 1 || ([[arrOptionsProd objectAtIndex:0] valueForKey:@"OptionId"] != (id)[NSNull null])) {
                    [cell.addArrowButton setImage:[UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"] forState:UIControlStateNormal];
                    [cell.addArrowButton removeTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.addArrowButton addTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                }
                else {
                    [cell.addArrowButton setImage:[UIImage imageNamed:@"ic_add_48pt.png"] forState:UIControlStateNormal];
                    [cell.addArrowButton removeTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.addArrowButton addTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    }
                }
            }
        else
        {
            NSMutableDictionary *dict = [[[menuDisplayArr objectAtIndex:indexPath.section] valueForKey:@"CustomProducts"] objectAtIndex:indexPath.row];
            
            cell.ItemTitle.text = [dict valueForKey:@"Name"];
            cell.ItemTitle.adjustsFontSizeToFitWidth = TRUE;
            cell.ItemPrice.text = [NSString stringWithFormat:@"£%@",[dict valueForKey:@"Price"]];

            if ([[[dict valueForKey:@"ProductComponents"] valueForKey:@"DisplayName"] isEqual:[NSNull null]])
                cell.ItemDescription.text = @"";
            else
                cell.ItemDescription.text = [self convertComponentsForArr:(NSArray *)[[dict valueForKey:@"ProductComponents"] valueForKey:@"DisplayName"]];
            
            
            if ([indexPath compare:expandedIndexPath] == NSOrderedSame) {
                [cell.addArrowButton setImage:[UIImage imageNamed:@"ic_keyboard_arrow_up_48pt.png"] forState:UIControlStateNormal];
                [cell.addArrowButton removeTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [cell.addArrowButton addTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                [cell.variantLbl setHidden:false];
                [cell.variantTxtField setHidden:false];
                [cell.optionAddButton setHidden:false];
                [cell.optionsPriceLbl setHidden:false];
                [cell.includingOptionsLbl setHidden:false];
                
                variantArr = [[NSMutableArray alloc] init];
                variantArr = [dict valueForKey:@"ProductComponents"];
                
                [cell.variantLbl setText:@"Variant"];
                
                selectedPickerContent = [variantArr objectAtIndex: 0];
                
                NSString * str = [NSString stringWithFormat:@"%@ ",[selectedPickerContent valueForKey:@"DisplayName"]];
                
                cell.variantTxtField.text = str;
                cell.variantTxtField.hidden = TRUE;
                UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
                [toolBar setBarStyle:UIBarStyleBlackOpaque];
                UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
                customButton.frame = CGRectMake(0, 0, 60, 33);
                [customButton addTarget:self action:@selector(pickerViewDoneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                customButton.showsTouchWhenHighlighted = YES;
                [customButton setTitle:@"Done" forState:UIControlStateNormal];
                
                UIBarButtonItem *barCustomButton =[[UIBarButtonItem alloc] initWithCustomView:customButton];
                UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
                toolBar.items = [[NSArray alloc] initWithObjects:flexibleSpace,barCustomButton,nil];
               
                cell.variantTxtField.inputAccessoryView = toolBar;
                cell.variantTxtField.delegate = self;
                cell.variantTxtField.userInteractionEnabled = FALSE;
                
                //Ashwani :: Set price from component arr
                cell.optionsPriceLbl.text = [NSString stringWithFormat:@"£%@",[dict valueForKey:@"Price"]];
                
                //TEMP To add multiple textfields for each variant - Dipen Sekhsaria
                
                 int y = cell.variantTxtField.frame.origin.y + cell.variantTxtField.frame.size.height;
                arraySelect = [[NSMutableArray alloc] init];
                
                for (int i = 0; i< [variantArr count]; i++) {
                    
                    
                    UIButton *productbutton = [UIButton buttonWithType:UIButtonTypeCustom];
                    productbutton.frame = CGRectMake(cell.variantTxtField.frame.origin.x, y + 10, cell.variantTxtField.frame.size.width, cell.variantTxtField.frame.size.height);
                    productbutton.showsTouchWhenHighlighted = YES;
                    [productbutton setBackgroundColor:[UIColor  clearColor]];
                    
                    productbutton.tag = i+2000;
                    //productbutton.tag = [[[variantArr objectAtIndex:i] valueForKey:@"ProductComponentId"] intValue]+2000;
                    [productbutton setTitle:[[variantArr objectAtIndex:i] valueForKey:@"DisplayName"] forState:UIControlStateNormal];
                    [productbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    productbutton.layer.cornerRadius = 4.0f;
                    productbutton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    productbutton.layer.borderWidth = 0.3;
                    productbutton.titleLabel.font = [UIFont systemFontOfSize:14.0];
                    [productbutton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
                    productbutton.layer.borderColor = [UIColor lightGrayColor].CGColor;
                    
                    if([[[variantArr objectAtIndex:i] valueForKey:@"IsOptionsExist"] boolValue]== TRUE || [[[variantArr objectAtIndex:i] valueForKey:@"IsToppingsExist"] boolValue]== TRUE)
                    {
                        //Ashwani :: Check here if product has toppings or variants
                        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(productbutton.frame.size.width-30, 0, 30, 30)];
                        imgView.image = [UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"];
                        [productbutton addSubview:imgView];
                        [productbutton setTitle:@"" forState:UIControlStateNormal];
                        [productbutton addTarget:self action:@selector(ProductbtnTapped:) forControlEvents:UIControlEventTouchUpInside];
                        
                        NSMutableDictionary *tempDict = [[variantArr objectAtIndex:i] mutableCopy];
                        [tempDict setObject:[dict valueForKey:@"Price"] forKey:@"offerPrice"];
                        [arraySelect addObject:tempDict];
                        
                        //Ashwani :: Oct 16 2015 Set prompt text from listing
                        [productbutton setTitle:[[variantArr objectAtIndex:i] valueForKey:@"DisplayName"] forState:UIControlStateNormal];
                    }
                    
                    //Ashwani :: Add all objects to selected array when it is uploaded to table
                    if([selectedComponentPickerContent count] == i)
                    {
                        NSMutableDictionary *tempDict = [[variantArr objectAtIndex:i] mutableCopy];
                        [tempDict setObject:[dict valueForKey:@"Price"] forKey:@"offerPrice"];
                        [selectedComponentPickerContent addObject:tempDict];
                    }
                    
                 [cell addSubview:productbutton];
                    
                y += cell.variantTxtField.frame.size.height +10;
                  
                }
                
                [cell.optionAddButton removeTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [cell.optionAddButton addTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                cell.optionAddButton.tag = (indexPath.section * 1000) + indexPath.row;
                
            }
            else {
                
                [cell.variantLbl setHidden:true];
                [cell.variantTxtField setHidden:true];
                [cell.optionAddButton setHidden:true];
                [cell.optionsPriceLbl setHidden:true];
                [cell.includingOptionsLbl setHidden:true];
                
                NSMutableArray *arrOptionsProd = [[NSMutableArray alloc] init];
                arrOptionsProd = [dict valueForKey:@"ProductComponents"];
                if ([[dict valueForKey:@"ProductComponents"] count] > 1 || ([[arrOptionsProd objectAtIndex:0] valueForKey:@"OptionId"] != (id)[NSNull null])) {
                    
                    [cell.addArrowButton setImage:[UIImage imageNamed:@"ic_keyboard_arrow_down_48pt.png"] forState:UIControlStateNormal];
                    [cell.addArrowButton removeTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.addArrowButton addTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    
                }
                else {
                    [cell.addArrowButton setImage:[UIImage imageNamed:@"ic_add_48pt.png"] forState:UIControlStateNormal];
                    [cell.addArrowButton removeTarget:self action:@selector(downButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.addArrowButton addTarget:self action:@selector(addButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                }
            }

        }
        cell.addArrowButton.tag = (indexPath.section * 1000) + indexPath.row;
        
        return cell;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    //if(self.dropdownView)
    
    if(tableView  == tableViewOptPicker)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        NSMutableArray *arrOptionItemId = [pickerOptArr valueForKey:@"OptionItemId"];
        NSMutableArray *arrOptionItemIdSelected = [selectedOptItems valueForKey:@"OptionItemId"];
        if([arrOptionItemIdSelected containsObject:[arrOptionItemId objectAtIndex:indexPath.row]])
        {
            int index = (int)[arrOptionItemIdSelected indexOfObject:[arrOptionItemId objectAtIndex:indexPath.row]];
            NSMutableArray *tempArr = [selectedOptItems mutableCopy];
            [tempArr removeObjectAtIndex:index];
            selectedOptItems = tempArr;
        }
        else
        {
            if([selectedOptItems count] == maxselect)
            {
                UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Voujon"
                                                             message:[@"Only select upto " stringByAppendingFormat:@"%d items",maxselect]
                                                            delegate:self
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil, nil];
                [al show];
                return;
            }
            [selectedOptItems addObject:[pickerOptArr objectAtIndex:indexPath.row]];
        }
        
        //Ashwani :: Set item name on table after selecteion of items
        arrSelectedprodOptionsPickerContent = selectedOptItems;
        ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
        cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
        
        NSString *str = @"";
        for(int i = 0; i < [arrSelectedprodOptionsPickerContent count]; i++)
        {
            if(i > 0)
                str = [str stringByAppendingFormat:@" & %@ ",[[arrSelectedprodOptionsPickerContent objectAtIndex:i] valueForKey:@"Name"]];
            else
                str = [NSString stringWithFormat:@"%@ ",[[arrSelectedprodOptionsPickerContent objectAtIndex:i] valueForKey:@"Name"]];
        }
        UIButton *btn = (UIButton *)[cell viewWithTag:tableViewOptPicker.tag+10000];
        if(str != nil || (![str isEqualToString:@""]))
            [btn setTitle:str forState:UIControlStateNormal];
        
        [tableViewOptPicker reloadData];
    }
    else if(tableView == tblOfferVarients)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        SelVariantIndex = (int)indexPath.row;
        
        
         [tblOfferVarients reloadData];
    }
    else if(tableView == tblToppingPicker)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if(tableView == tblToppingPickerForStandard)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        //Ashwanni :: Check here both the optionitemid and product varient id for remove or add objects to selected topping array
        
        NSMutableArray *arrProductVarientId = [selectedToppings valueForKey:@"ProductVariantId"];
        NSMutableArray *arrOptionId = [selectedToppings valueForKey:@"OptionId"];
        if([arrProductVarientId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"ProductVariantId"]] && [arrOptionId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionId"]])
        {
            int index = (int)[arrOptionId indexOfObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionId"]];
            
            NSMutableDictionary *dictTemp = [[selectedToppings objectAtIndex:index] mutableCopy];
            NSMutableArray *tempArr = [[NSMutableArray alloc] init];
            tempArr = [[dictTemp valueForKey:@"ProductOptions"] mutableCopy];
            
            NSMutableArray *arrProductOptionItemId = [tempArr valueForKey:@"OptionItemId"];
            if([arrProductOptionItemId containsObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionItemId"]])
            {
                int index1 = (int)[arrProductOptionItemId indexOfObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionItemId"]];
                [tempArr removeObjectAtIndex:index1];
                
                //Set dictionary after replacing
                [dictTemp setObject:tempArr forKey:@"ProductOptions"];
            }
            else
            {
                if([tempArr count] == maxselect)
                {
                    UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Voujon"
                                                                 message:[@"Only select upto " stringByAppendingFormat:@"%d items",maxselect]
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil, nil];
                    [al show];
                    return;
                }
                [tempArr addObject:[toppingPickerOptionArray objectAtIndex:indexPath.row]];
                [dictTemp setObject:tempArr forKey:@"ProductOptions"];
            }
            [selectedToppings removeObjectAtIndex:index];
            [selectedToppings addObject:dictTemp];
            
        }
        else
        {
            NSMutableDictionary *dictItem = [[NSMutableDictionary alloc] init];
            [dictItem setObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"ProductVariantId"] forKey:@"ProductVariantId"];
            [dictItem setObject:[[toppingPickerOptionArray objectAtIndex:indexPath.row] valueForKey:@"OptionId"] forKey:@"OptionId"];
            NSMutableArray *tempArr = [[NSMutableArray alloc] init];
            [tempArr addObject:[toppingPickerOptionArray objectAtIndex:indexPath.row]];
            [dictItem setObject:tempArr forKey:@"ProductOptions"];
            [selectedToppings addObject:dictItem];
        }
        [tblToppingPickerForStandard reloadData];
    }
    else if(tableView  == tableViewPicker)
    {
        //Picker for Offer options
//        IsItemSelectionAllow = FALSE;
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//        
//        if ([selectedItems containsObject:indexPath])
//        {
//            [selectedItems removeObject:indexPath];
//            NSString *optionId = [[selctedArrItems objectAtIndex:indexPath.row] valueForKey:@"OptionId"];
//            //Ashwani :: Add only those items who has toppings
//            if(optionId != (id)[NSNull null])
//            {
//                if([arrToppings containsObject:[selctedArrItems objectAtIndex:indexPath.row]])
//                {
//                //if()
//                    int index = (int)[arrToppings indexOfObject:[selctedArrItems objectAtIndex:indexPath.row]];
//                    [arrToppings removeObjectAtIndex:index];
//                }
//            }
//        }
//        else
//        {
//            if([selectedItems count] == maxselect)
//            {
//                UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Voujon"
//                                                              message:[@"Only select upto " stringByAppendingFormat:@"%d items",maxselect]
//                                                             delegate:self
//                                                    cancelButtonTitle:@"OK"
//                                                    otherButtonTitles:nil, nil];
//                [al show];
//                return;
//            }
//            [selectedItems addObject:indexPath];
//            NSMutableArray *tempArr = [selctedArrItems objectAtIndex:indexPath.row];
//            NSString *optionId = [[tempArr objectAtIndex:0] valueForKey:@"OptionId"];
//            //Ashwani :: Add only those items who has toppings
//            if(optionId != (id)[NSNull null])
//                [arrToppings addObject:[selctedArrItems objectAtIndex:indexPath.row]];
//        }
//        [tableViewPicker reloadData];
    }
    
else if(tableView == self.menuTableView)
    {
        //Ashwani :: scroll table to selected items
        [self.dropdownView hide];
        expandedIndexPath = nil;
        if(indexPath.row == 0)
        {
            self.currentMapTypeIndex = indexPath.row;
            [self.orderMenuTblView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.currentMapTypeIndex]
                                         atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        else
        {
            self.currentMapTypeIndex = indexPath.row;
            [self.orderMenuTblView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.currentMapTypeIndex-1]
                                         atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeaderView = [[UIView alloc] init];
    
    if(tableView != self.menuTableView && tableView != tableViewPicker && tableView != tableViewOptPicker && tableView != tblToppingPicker && tableView != tblToppingPickerForStandard && tableView != tblOfferVarients)
    {
        sectionHeaderView.frame = CGRectMake(10, 5, tableView.frame.size.width-20, 40.0);
        sectionHeaderView.backgroundColor = [UIColor clearColor];
        
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:
                                CGRectMake(10, 5, sectionHeaderView.frame.size.width, 30.0)];
        
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textAlignment = NSTextAlignmentLeft;
        [headerLabel setFont:[UIFont fontWithName:@"Verdana" size:20.0]];
        headerLabel.numberOfLines = 1;
        headerLabel.adjustsFontSizeToFitWidth = TRUE;
        [sectionHeaderView addSubview:headerLabel];
        
        if (IsSearch) {
            headerLabel.text = selectedCategory;
        }
        else
        {
            headerLabel.text = [[categoryArr objectAtIndex:section] valueForKey:@"CategoryName"];
        }
        
    }
    return sectionHeaderView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *lineView = [[UIView alloc] init];
    //if(!self.dropdownView)
    if(tableView != self.menuTableView && tableView != tableViewPicker && tableView != tableViewOptPicker && tableView != tblToppingPicker && tableView != tblToppingPickerForStandard && tableView != tblOfferVarients)
    {
        lineView.frame = CGRectMake(10, 0, tableView.frame.size.width-20, 1);
        lineView.backgroundColor = [UIColor blackColor];
        return lineView;
    }
    
    return lineView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //if(!self.dropdownView)
    if(tableView != self.menuTableView && tableView != tableViewPicker && tableView != tableViewOptPicker && tableView != tblToppingPicker && tableView != tblToppingPickerForStandard && tableView != tblOfferVarients)
        return 40.0f;
    else
        return 0;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    //if(!self.dropdownView)
    if(tableView != self.menuTableView && tableView != tableViewPicker && tableView != tableViewOptPicker && tableView != tblToppingPicker && tableView != tblToppingPickerForStandard && tableView != tblOfferVarients)
        return 1.0f;
    else
        return 0;
}


#pragma mark - ADD OFFER -
-(IBAction)AddOffer:(id)sender
{
    if([selVariants count] == maxselect)
    {
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Voujon"
                                                     message:[@"Only select upto " stringByAppendingFormat:@"%d items",maxselect]
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil, nil];
        [al show];
        return;
    }
    
    
   // if(IsItemSelectionAllow)
    //{
//        NSMutableArray *arrCompId = [selectedComponentPickerContent valueForKey:@"ProductVariantId"];
//        if([arrCompId containsObject:[[arr objectAtIndex:0] valueForKey:@"ProductVariantId"]])
//        {
//            [selectedItems addObject:indexPath];
//            //Ashwani :: March 03, 2016 If Toppings are already selected then add selected data
//            [arrToppings addObject:[selctedArrItems objectAtIndex:indexPath.row]];
//        }
   // }
    
//    int count = 1;
//    NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
//    NSMutableArray *arrProdIds = [selVariants valueForKey:@"ProductVariantId"];
//    if([arrProdIds containsObject:[[selctedArrItems objectAtIndex:[sender tag]] valueForKey:@"ProductVariantId"]])
//    {
//        int index = [arrProdIds indexOfObject:[[selctedArrItems objectAtIndex:[sender tag]] valueForKey:@"ProductVariantId"]];
//        count = [[[selVariants objectAtIndex:index] valueForKey:@"quantity"] intValue];
//        count++;
//        tempDic = [[selctedArrItems objectAtIndex:[sender tag]] mutableCopy];
//        [tempDic setObject:[@(count) stringValue] forKey:@"quantity"];
//        
//    }
//    else
//    {
//        tempDic = [[selctedArrItems objectAtIndex:[sender tag]] mutableCopy];
//        [tempDic setObject:[@(count) stringValue] forKey:@"quantity"];
//    }
    [selVariants addObject:[selctedArrItems objectAtIndex:[sender tag]]];
    [tableViewPicker reloadData];
}

-(IBAction)DeleteOffer:(id)sender
{
    //int count = 0;
    //NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
    NSMutableArray *arrProdIds = [selVariants valueForKey:@"ProductVariantId"];
    if([arrProdIds containsObject:[[selctedArrItems objectAtIndex:[sender tag]] valueForKey:@"ProductVariantId"]])
    {
        int index = [arrProdIds indexOfObject:[[selctedArrItems objectAtIndex:[sender tag]] valueForKey:@"ProductVariantId"]];
        [selVariants removeObjectAtIndex:index];
//        count = [[[selVariants objectAtIndex:index] valueForKey:@"quantity"] intValue];
//        count--;
//        if(count>0)
//        {
//            tempDic = [[selctedArrItems objectAtIndex:[sender tag]] mutableCopy];
//            [tempDic setObject:[@(count) stringValue] forKey:@"quantity"];
//        }
//        else
//        {
//            [selVariants removeObjectAtIndex:index];
//        }
    }
    [tableViewPicker reloadData];
}

#pragma mark - ADD TOPPINGS -
-(IBAction)AddToppings:(id)sender
{
    if([selToppings count] == maxselect)
    {
        UIAlertView *al = [[UIAlertView alloc] initWithTitle:@"Voujon"
                                                     message:[@"Only select upto " stringByAppendingFormat:@"%d items",maxselect]
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil, nil];
        [al show];
        return;
    }
    
    [selToppings addObject:[toppingPickerOptionArray objectAtIndex:[sender tag]]];
    [tblToppingPicker reloadData];
}

-(IBAction)DeleteToppings:(id)sender
{
    NSMutableArray *arrProdIds = [selToppings valueForKey:@"OptionItemId"];
    if([arrProdIds containsObject:[[toppingPickerOptionArray objectAtIndex:[sender tag]] valueForKey:@"OptionItemId"]])
    {
        int index = (int)[arrProdIds indexOfObject:[[toppingPickerOptionArray objectAtIndex:[sender tag]] valueForKey:@"OptionItemId"]];
        [selToppings removeObjectAtIndex:index];
    }
    [tblToppingPicker reloadData];
}

#pragma mark - PICKERVIEW DELEGATE AND DATASOURCE

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{

    if(pickerView == picker1)
    {
        //Ashwani
        txtTag = (int)(pickerView.tag)+2000;
        return [selctedArrItems count];
    }
    //Ashwani :: Select item for souces options
    else if(pickerView == prodOptionPicker)
    {
        //Ashwani
        txtTag = (int)(pickerView.tag);
        return [pickerOptArr count];
    }
    else if(pickerView == variantPicker)
    {
        //Ashwani
        //txtTag = (int)(pickerView.tag);
        return [selVariants count];
    }
    else
    {
        txtTag = (int)(pickerView.tag)+99;
        return [variantArr count];
    }
}


- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view1
{
    UILabel* pickerLabel = (UILabel*)view1;

        if (!pickerLabel)
        {
            pickerLabel = [[UILabel alloc] init];
            pickerLabel.font = [UIFont systemFontOfSize:13.0];
            pickerLabel.textAlignment=NSTextAlignmentCenter;
            pickerLabel.adjustsFontSizeToFitWidth = YES;
        }
    
    if (pickerView == picker) {
        strOptionSelected = [[variantArr objectAtIndex:row] valueForKey:@"DisplayName"];
        NSString * str = [[variantArr objectAtIndex:row] valueForKey:@"DisplayName"];
        
        NSString *strPrice = [[variantArr objectAtIndex:row] valueForKey:@"Price"];
        if(strPrice != nil && (![strPrice isEqualToString:@""]))
            [pickerLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
        else
            [pickerLabel setText:[str stringByAppendingString:@" (£0)"]];

    }
    else if (pickerView  == strengthPicker){
        
        NSString * str = [[variantArr objectAtIndex:row] valueForKey:@"Name"];
        //[pickerLabel setText:[[variantArr objectAtIndex:row] valueForKey:@"Name"]];
        NSString *strPrice = [[variantArr objectAtIndex:row] valueForKey:@"Price"];
        if(strPrice != nil && (![strPrice isEqualToString:@""]))
            [pickerLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
        else
            [pickerLabel setText:[str stringByAppendingString:@" (£0)"]];

    }
    //Ashwani :: Select item for souces options
    else if(pickerView == prodOptionPicker)
    {
        
        //[pickerLabel setText:[[pickerOptArr objectAtIndex:row] valueForKey:@"Name"]];
        
        NSString * str = [[variantArr objectAtIndex:row] valueForKey:@"Name"];
        NSString *strPrice = [[variantArr objectAtIndex:row] valueForKey:@"Price"];
        if(strPrice != nil && (![strPrice isEqualToString:@""]))
            [pickerLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
        else
            [pickerLabel setText:[str stringByAppendingString:@" (£0)"]];
    }
    if(pickerView == picker1)
    {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        arr = [selctedArrItems objectAtIndex:row];
        NSString * str = [[arr objectAtIndex:0] valueForKey:@"DisplayName"];
       // [pickerLabel setText:str];
        
        NSString *strPrice = [[variantArr objectAtIndex:row] valueForKey:@"Price"];
        if(strPrice != nil && (![strPrice isEqualToString:@""]))
            [pickerLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
        else
            [pickerLabel setText:[str stringByAppendingString:@" (£0)"]];
        
    }
    if(pickerView == variantPicker)
    {
        //NSMutableArray *arr = [[NSMutableArray alloc] init];
        //arr = [selctedArrItems objectAtIndex:row];
        NSString * str = [[selVariants objectAtIndex:row] valueForKey:@"DisplayName"];
        [pickerLabel setText:str];
        
//        NSString *strPrice = [[variantArr objectAtIndex:row] valueForKey:@"Price"];
//        if(strPrice != nil && (![strPrice isEqualToString:@""]))
//            [pickerLabel setText:[str stringByAppendingFormat:@" (£%@)",strPrice]];
//        else
//            [pickerLabel setText:[str stringByAppendingString:@" (£0)"]];
        
    }
    
   return pickerLabel;
    
}

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    
    if (pickerView == picker1)
    {
        NSMutableArray *tempArr = [[[NSMutableArray alloc] initWithArray:selectedComponentPickerContent] mutableCopy];
        NSMutableArray *arr = [selctedArrItems objectAtIndex:row];
        NSString * str;
        for(int i = 0; i < [tempArr count]; i++)
        {
            if([[[[tempArr objectAtIndex:i] valueForKey:@"ComponentId"] stringValue] isEqualToString:selectedComponentID])
            {
                [tempArr replaceObjectAtIndex:i withObject:[arr objectAtIndex:0]];
               str = [[tempArr objectAtIndex:i] valueForKey:@"DisplayName"];
            }
        }
        selectedComponentPickerContent = tempArr;
        ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
        cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
        UIButton *btn = (UIButton *)[cell viewWithTag:txtTag];
        if(str != nil || (![str isEqualToString:@""]))
            [btn setTitle:str forState:UIControlStateNormal];
        
    }
    else if(pickerView == picker) {
      //Ashwani :: check this string to add item in cart
        strOptionSelected = [variantArr objectAtIndex:row];
        selectedPickerContent = [variantArr objectAtIndex:row];
    }
    //Ashwani :: Select item for souces options
    else if(pickerView == prodOptionPicker)
    {
        selectedprodOptionsPickerContent = [pickerOptArr objectAtIndex:row];
        NSLog(@"selectedprodOptionsPickerContent %@",selectedprodOptionsPickerContent);
        ListingCustomTableViewCell* cell = [[ListingCustomTableViewCell alloc] init];
        cell = (ListingCustomTableViewCell *)[self.orderMenuTblView cellForRowAtIndexPath:expandedIndexPath];
        NSLog(@"txt tag %d", txtTag);
        NSString *str = [NSString stringWithFormat:@"%@ ",[[pickerOptArr objectAtIndex:row] valueForKey:@"Name"]];
        UIButton *btn = (UIButton *)[cell viewWithTag:txtTag];
        if(str != nil || (![str isEqualToString:@""]))
            [btn setTitle:str forState:UIControlStateNormal];
    }
    else if(pickerView == variantPicker)
    {
        //NSString *str = [NSString stringWithFormat:@"%@ ",[[selVariants objectAtIndex:row] valueForKey:@"DisplayName"]];
        //txtVariantField.text = str;
        SelVariantIndex = (int)row;
    }
    else {
       
        selectedStrengthPickerContent = [variantArr objectAtIndex:row];
    }
    
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField endEditing:YES];
    return true;
}


#pragma mark - EVENTS

- (IBAction)categoryButtonTapped:(id)sender
{
    [self.menuTableView reloadData];
    [self showDropDownView];
}

- (IBAction)homeButtonTapped:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (IBAction)checkOutButtonTapped:(id)sender {
    
//    if ([self validateMinimumOrderAmount]) {
//        [self performSegueWithIdentifier:@"orderTimeAlertSegue" sender:nil];
//    }
//    else {
        [self performSegueWithIdentifier:@"showOrderDetailsSegue" sender:nil];
//    }
    
}

- (BOOL) validateMinimumOrderAmount {
    
    if ([[[[self.orderPriceLbl.text componentsSeparatedByString:@" "] lastObject] stringByReplacingOccurrencesOfString:@"£" withString:@""] floatValue] < [[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"] floatValue]) {
        
        alertType = true;
        
    }
    else {
        alertType = false;
    }
    
    return alertType;;
    
}


-(void) handleAlertDismiss {
    
    [[SharedContent sharedInstance] setIsRestoClosed:YES];
    [self performSegueWithIdentifier:@"showOrderDetailsSegue" sender:nil];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
//    if ([[segue identifier] isEqualToString:@"orderTimeAlertSegue1"]) {
//        
//        MZFormSheetSegue *formSheetSegue = (MZFormSheetSegue *)segue;
//        MZFormSheetController *formSheet = formSheetSegue.formSheetController;
//        formSheet.transitionStyle = MZFormSheetTransitionStyleBounce;
//        formSheet.cornerRadius = 8.0;
//        
//        NSString *deviceType = [UIDevice currentDevice].model;
//        
//        if([deviceType hasPrefix:@"iPad"])
//        {
//            formSheet.presentedFormSheetSize = CGSizeMake(600, 400);
//        }
//        else {
//            formSheet.presentedFormSheetSize = CGSizeMake(300, 200);
//        }
//        
//        formSheet.didTapOnBackgroundViewCompletionHandler = ^(CGPoint location) {
//            //didTapBackGroundView = true;
//        };
//        
//        formSheet.shadowRadius = 2.0;
//        formSheet.shadowOpacity = 0.3;
//        formSheet.shouldDismissOnBackgroundViewTap = YES;
//        formSheet.shouldCenterVertically = YES;
//        
//        
//        formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
//            [self handleAlertDismiss];
//            
//        };
//        
//    }
    if ([[segue identifier] isEqualToString:@"orderTimeAlertSegue"]) {
        
        AlertViewController* controller = (AlertViewController *)[segue destinationViewController];
        
        if (alertType) {
            controller.txt = [NSString stringWithFormat:@"Please add more items to make total order amount upto £%@",[[[[SharedContent sharedInstance] appSettingsDict] valueForKey:@"DeliveryPolicy"] valueForKey:@"DeliveryThreshold"]];
        }
        else {
            controller.txt = @"Hello ! It seems we are closed now. You can order now and we'll process your order once open ! Sorry for the inconvenience.";
        }
    
        
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

#pragma mark - Alert View Delegate -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100000)
    {
        if (buttonIndex == 1)
        {
            NSMutableArray *arrTemp = [[NSMutableArray alloc] init];
            NSLog(@"selected Items %@", selectedItems);
            for(int i = 0; i < selectedItems.count; i++)
            {
                [arrTemp addObject:[selectedItems objectAtIndex:i]];
            }
            [selectedItems addObjectsFromArray:arrTemp];
        }
    }
    
}


- (NSString *) convertComponentsForArr:(NSArray *) compArr {
    
    NSString* retStr = @"";
    
    for (int i = 0; i<compArr.count; i++) {
        
        if (i == 0) {
            retStr = [compArr objectAtIndex:i];
        }
        else {
            retStr = [retStr stringByAppendingString:[NSString stringWithFormat:@", %@",[compArr objectAtIndex:i]]];
        }
        
    }
    
    return retStr;
    
}

@end
