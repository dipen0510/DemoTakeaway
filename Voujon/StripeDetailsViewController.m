//
//  StripeDetailsViewController.m
//  W4FirePizza
//
//  Created by Dipen Sekhsaria on 05/05/16.
//  Copyright © 2016 Dipen Sekhsaria. All rights reserved.
//

#import "StripeDetailsViewController.h"

@interface StripeDetailsViewController ()

@end

@implementation StripeDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.paymentTextField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 90, CGRectGetWidth(self.view.frame) - 30, 50)];
    self.paymentTextField.delegate = self;
    [self.view addSubview:self.paymentTextField];
    
    self.saveButton.enabled = NO;
    self.saveButton.alpha = 0.3;
    self.saveButton.layer.borderColor = [[UIColor colorWithRed:178./255. green:95./255. blue:16./255. alpha:1.0] CGColor];
    self.saveButton.layer.borderWidth = 1.0;
    self.saveButton.layer.cornerRadius = 10.0;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    // Toggle navigation, for example
    self.saveButton.enabled = textField.isValid;
    
    if (self.saveButton.enabled) {
        self.saveButton.alpha = 1.0;
    }
    else {
        self.saveButton.alpha = 0.3;
    }
    
}


- (IBAction)save:(UIButton *)sender {
    
    [SVProgressHUD showWithStatus:@"Processing details"];
    
    
    [self startPaymentProcess];
    
}

- (void) startPaymentProcess {
    
    [[STPAPIClient sharedClient]
     createTokenWithCard:self.paymentTextField.cardParams
     completion:^(STPToken *token, NSError *error) {
         if (error) {
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self handleStripeError:error];
             });
             
             
         } else {
             [self createBackendChargeWithToken:token completion:^(PKPaymentAuthorizationStatus status) {
             }];
         }
     }];
    
}


- (void)createBackendChargeWithToken:(STPToken *)token
                          completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    NSURL *url = [NSURL URLWithString:@"http://nawazrestaurantleeds.ibrarhussain.co.uk/payment.php"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *body     = [self getJsonStringForStripeForToken:token.tokenId];
    request.HTTPBody   = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data,
                                   NSURLResponse *response,
                                   NSError *error) {
                   if (error) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           [self handleStripeError:error];
                       });
                   } else {
                       
                       NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                       
                       [[SharedContent sharedInstance] setStripeToken:token.tokenId];
                       
                       if ([@"Success" isEqualToString:[responseDict valueForKey:@"status"]]) {
                           
                           
                           [[NSNotificationCenter defaultCenter] postNotificationName:@"StripePaymentSuccessNotification" object:nil];
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [SVProgressHUD dismiss];
                               [self dismissViewControllerAnimated:YES completion:nil];
                           });
                           
                           
                       }
                       else {
                           
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [SVProgressHUD dismiss];
                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                               message:@"Please try again"
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil];
                               [alert show];
                           });
                           
                           
                           
                       }
                       
                       
                       
                   }
               }];
    [task resume];
}


-(NSString*)getJsonStringForStripeForToken:(NSString *)token {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self prepareDictonaryForStripe:token] options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

-(NSDictionary *)prepareDictonaryForStripe:(NSString *)token  {
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:[self updatePriceAfterSelection] forKey:@"amount"];
    [dict setObject:@"gbp" forKey:@"currency"];
    [dict setObject:token forKey:@"stripeToken"];
    [dict setObject:@"" forKey:@"description"];
    
    return dict;
}

- (void)handleStripeError:(NSError *) error {
    
    [SVProgressHUD dismiss];
    
    //1
    if ([error.domain isEqualToString:@"StripeDomain"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    //2
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Please try again"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
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


//Ashwani :: This function will be use to get updated price after discount
-(NSNumber *)updatePriceAfterSelection
{
    //Ashwani :: Nov 05, get Discount Items cost here from settings
    
    //NSLog(@"cartArr:%@",[[SharedContent sharedInstance] cartArr]);
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    //Ashwani :: Nov 05, 2015 Add discount offer info here for Get Discount
    DiscountPercentage = [dict valueForKey:@"DiscountRate"];
    MinimumRateForDiscount = [dict valueForKey:@"DiscountThreshold"];
    
    double finalPriceToCharge = 0.0;
    
    double calculatedPrice = [[[self getTotalPrice] stringByReplacingOccurrencesOfString:@"£" withString:@""] doubleValue];
    double minimumAmountForDiscount = [MinimumRateForDiscount doubleValue];
    if([DiscountPercentage floatValue] > 0)
    {
        //Ashwani :: Nov 05, 2015 get here price of discount for
        if(calculatedPrice >= minimumAmountForDiscount)
        {
            double discountPrice = calculatedPrice*[DiscountPercentage doubleValue];
            double totalPrice = calculatedPrice-discountPrice;
            
            finalPriceToCharge = totalPrice;
        }
        else
        {
            finalPriceToCharge = calculatedPrice;
            
        }
    }
    else
    {
        finalPriceToCharge = calculatedPrice;
    }
    
    finalPriceToCharge = (finalPriceToCharge + [[SharedContent sharedInstance] extraDistanceDeliveryCharge]);
    
    //return [NSString stringWithFormat:@"%f",(finalPriceToCharge * 100)];
    return [NSNumber numberWithDouble:(finalPriceToCharge)];
}
//*********************END***************************//
- (NSString *) getTotalPrice {
    
    double price = 0.0;
    
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    tmpArr  = [[[SharedContent sharedInstance] cartArr] valueForKey:@"Price"];
    
    for (int i = 0; i < tmpArr.count; i++) {
        
        price = price + [[tmpArr objectAtIndex:i] doubleValue];
        
    }
    
    return [NSString stringWithFormat:@"£%.2f",price];
    
}
- (IBAction)backButtonTapped:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self.view endEditing:YES];
    
}
@end
