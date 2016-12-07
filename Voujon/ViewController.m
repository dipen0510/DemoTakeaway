//
//  ViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "ViewController.h"
#import <Stripe/Stripe.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.RefreshButton.hidden = TRUE;
    //settingsDict = [[NSMutableDictionary alloc] init];
    
    deliveryTimingArr = [[NSMutableArray alloc] init];
    collectionTimingArr = [[NSMutableArray alloc] init];
    
    [self getSettingsFromServer];
    
    //Ashwani :: Nov 02 2015 Set local notification for Session Expiry
    [[SharedContent sharedInstance] setCurrentViewController:@"ViewController"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popUpScreen) name:@"ViewController" object:nil];
    //------------------- END -----------------------
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) getSettingsFromServer {
    
    [SVProgressHUD showWithStatus:@""];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:kBusinessID forKey:@"BusinessId"];
    
    
    DataSyncManager* manager = [[DataSyncManager alloc] init];
    manager.serviceKey = kGetSettingsNew;
    manager.delegate = self;
    [manager startPOSTWebServicesWithData:dict];
    
}

#pragma mark - DATASYNCMANGER DELEGATE

-(void)didFinishServiceWithSuccess:(NSMutableDictionary *)responseData andServiceKey:(NSString *)requestServiceKey {
    
    NSMutableDictionary* responseDict = [[NSMutableDictionary alloc] initWithDictionary:responseData];
    
    if ([requestServiceKey isEqualToString:kGetSettingsNew]) {
        
        NSString* yourString = [responseDict valueForKey:@"SettingXml"];
        NSDictionary *xmlDoc = [NSDictionary dictionaryWithXMLString:yourString];
        
        NSLog(@"Response: %@)",xmlDoc);
        [[SharedContent sharedInstance] setPaypalEmail:[responseDict valueForKey:@"PaypalEmail"]];
        
        
        //NSLog(@"PaypalEmail: %@)",[[SharedContent sharedInstance] PaypalEmail]);
        [[SharedContent sharedInstance] setAppSettingsDict:xmlDoc];
        [self setupPoilicyData];
        
        
        if ([responseDict valueForKey:@"Stripe"] && ![[responseDict valueForKey:@"Stripe"] isEqual:[NSNull null]]) {
            [[SharedContent sharedInstance] setStripePublishKey:[responseDict valueForKey:@"Stripe"]];
            [Stripe setDefaultPublishableKey:[[SharedContent sharedInstance] StripePublishKey]];
        }
        if ([responseDict valueForKey:@"SecretKey"] && ![[responseDict valueForKey:@"SecretKey"] isEqual:[NSNull null]]) {
            [[SharedContent sharedInstance] setPaypalSecretKey:[responseDict valueForKey:@"SecretKey"]];
//            [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentSandbox : [[SharedContent sharedInstance] PaypalSecretKey]}];
        }
        
        

        
    }
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:@"Data downloaded successfully"];
    
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


-(NSString *) getDayForNumber:(int)num {
    
    if (num == 0) {
        return @"Mon";
    }
    else if (num == 1) {
        return @"Tue";
    }
    else if (num == 2) {
        return @"Wed";
    }
    else if (num == 3) {
        return @"Thu";
    }
    else if (num == 4) {
        return @"Fri";
    }
    else if (num == 5) {
        return @"Sat";
    }
    return @"Sun";
    
}

- (void) setupPoilicyData {
    
    NSDictionary* dict = [[NSDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    
    for (int i = 0; i<7; i++) {
        
        
        NSString* deliveryFromHours = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"DeliverySlot"] valueForKey:@"From"] valueForKey:@"Hours"];
        NSString* deliveryFromMinutes = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"DeliverySlot"] valueForKey:@"From"] valueForKey:@"Minutes"];
        NSString* deliveryToHours = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"DeliverySlot"] valueForKey:@"To"] valueForKey:@"Hours"];
        NSString* deliveryToMinutes = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"DeliverySlot"] valueForKey:@"To"] valueForKey:@"Minutes"];
        
        NSString* collectionFromHours = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"CollectionSlot"] valueForKey:@"From"] valueForKey:@"Hours"];
        NSString* collectionFromMinutes = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"CollectionSlot"] valueForKey:@"From"] valueForKey:@"Minutes"];
        NSString* collectionToHours = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"CollectionSlot"] valueForKey:@"To"] valueForKey:@"Hours"];
        NSString* collectionToMinutes = [[[[[dict valueForKey:@"TimeTable"] valueForKey:[self getDayForNumber:i]] valueForKey:@"CollectionSlot"] valueForKey:@"To"] valueForKey:@"Minutes"];
        
        if ([deliveryFromHours length] == 1) {
            deliveryFromHours = [NSString stringWithFormat:@"0%@",deliveryFromHours];
        }
        if ([deliveryFromMinutes length] == 1) {
            deliveryFromMinutes = [NSString stringWithFormat:@"0%@",deliveryFromMinutes];
        }
        if ([deliveryToHours length] == 1) {
            deliveryToHours = [NSString stringWithFormat:@"0%@",deliveryToHours];
        }
        if ([deliveryToMinutes length] == 1) {
            deliveryToMinutes = [NSString stringWithFormat:@"0%@",deliveryToMinutes];
        }
        
        if ([collectionFromHours length] == 1) {
            collectionFromHours = [NSString stringWithFormat:@"0%@",collectionFromHours];
        }
        if ([collectionFromMinutes length] == 1) {
            collectionFromMinutes = [NSString stringWithFormat:@"0%@",collectionFromMinutes];
        }
        if ([collectionToHours length] == 1) {
            collectionToHours = [NSString stringWithFormat:@"0%@",collectionToHours];
        }
        if ([collectionToMinutes length] == 1) {
            collectionToMinutes = [NSString stringWithFormat:@"0%@",collectionToMinutes];
        }
        
        //#GD:1012_2015 if time is 00:00-00:00 that means its 24 hours, starting from 00:00-23:59
        if([deliveryToHours intValue] == 0)
        {
            deliveryToHours = @"23";
            deliveryToMinutes = @"59";
        }
        
        if([collectionToHours intValue] == 0)
        {
            collectionToHours = @"23";
            collectionToMinutes = @"59";
        }

        
        [deliveryTimingArr addObject:[NSString stringWithFormat:@"%@:%@ - %@:%@",deliveryFromHours,deliveryFromMinutes,deliveryToHours,deliveryToMinutes]];
        [collectionTimingArr addObject:[NSString stringWithFormat:@"%@:%@ - %@:%@",collectionFromHours,collectionFromMinutes,collectionToHours,collectionToMinutes]];
        
        
    }
    
    [[SharedContent sharedInstance] setDeliveryTimingArr:deliveryTimingArr];
    [[SharedContent sharedInstance] setCollectionTimingArr:collectionTimingArr];
    
}

- (IBAction)RefreshButtonTapped:(id)sender
{
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:
                            @"Credits",
                            @"Refresh",
                            nil];
    popup.tag = 1;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    //[self FBShare];
                    [self showAlert];
                    break;
                case 1:
                    //[self TwitterShare];
                    break;
                
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

-(void)showAlert
{
    MODropAlertView *alertView = [[MODropAlertView alloc]initDropAlertWithTitle:@"Voujon Message"
                                                                    description:@"Coming Soon"
                                                                  okButtonTitle:@"OK"
                                                              cancelButtonTitle:nil];
    alertView.delegate = self;
    [alertView show];
}

#pragma mark custom alert delegates
- (void)alertViewPressButton:(MODropAlertView *)alertView buttonType:(DropAlertButtonType)buttonType
{
    [alertView dismiss];
}

- (void)alertViewWillAppear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}
- (void)alertViewDidAppear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)alertViewWilldisappear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)alertViewDidDisappear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}

- (IBAction)orderButtonTapped:(id)sender {
    
    if ([[[SharedContent sharedInstance] appSettingsDict] count] > 0) {
        [self performSegueWithIdentifier:@"showOrderSegue" sender:nil];
    }
    else {
        [self getSettingsFromServer];
    }
    
}

- (IBAction)findButtonTapped:(id)sender {
    
    if ([[[SharedContent sharedInstance] appSettingsDict] count] > 0) {
        [self performSegueWithIdentifier:@"showFindSegue" sender:nil];
    }
    else {
        [self getSettingsFromServer];
    }
    
}

- (IBAction)infoButtonTapped:(id)sender {
    
    if ([[[SharedContent sharedInstance] appSettingsDict] count] > 0) {
        [self performSegueWithIdentifier:@"showInfoSegue" sender:nil];
    }
    else {
        [self getSettingsFromServer];
    }
    
}

-(void)popUpScreen
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}


- (IBAction)webLinkButtonTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.rh-it-solutions.co.uk"]];
}
@end
