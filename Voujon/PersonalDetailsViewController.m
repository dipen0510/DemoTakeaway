//
//  PersonalDetailsViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "PersonalDetailsViewController.h"

@interface PersonalDetailsViewController () {
    BOOL showKeyboardAnimation;
    CGPoint viewCenter;
}

@end

@implementation PersonalDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.firstNameTxtField setText:@""];
    self.firstNameTxtField.delegate = self;
    
    [self.lastNameTxtField setText:@""];
    self.lastNameTxtField.delegate = self;
    
    [self.emailTxtField setText:@""];
    self.emailTxtField.delegate = self;
    
    [self.phoneTxtField setText:@""];
    self.phoneTxtField.delegate = self;
    self.phoneTxtField.keyboardType = UIKeyboardTypeNumberPad;
    
    
    showKeyboardAnimation = true;
    viewCenter = self.view.center;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    
    if ([self isFormValid]) {
        
        [[NSUserDefaults standardUserDefaults] setObject:[self prepareDictionarForOrderDetails] forKey:@"SavedUserDetails"];
        
        [[SharedContent sharedInstance] setOrderDetailsDict:[self prepareDictionarForOrderDetails]];
        [self performSegueWithIdentifier:@"showConfirmOrderSegue" sender:nil];
        
    }
    else {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Invalid Details" message:@"Please check the form and try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
    }
    
    
}


- (BOOL) isFormValid {
    
    if ([self.firstNameTxtField.text isEqualToString:@""]) {
        return false;
    }
    if ([self.lastNameTxtField.text isEqualToString:@""]) {
        return false;
    }
    if ([self.emailTxtField.text isEqualToString:@""]) {
        return false;
    }
    if ([self.phoneTxtField.text isEqualToString:@""]) {
        return false;
    }
    if (![self validateEmailWithString:self.emailTxtField.text]) {
        return false;
    }
    
    return true;
    
}

- (BOOL)validateEmailWithString:(NSString*)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{1,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

- (NSMutableDictionary *) prepareDictionarForOrderDetails {
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    dict = [[SharedContent sharedInstance] orderDetailsDict];
    
    [dict setObject:self.firstNameTxtField.text forKey:@"firstName"];
    [dict setObject:self.lastNameTxtField.text forKey:@"lastName"];
    [dict setObject:self.emailTxtField.text forKey:@"email"];
    [dict setObject:self.phoneTxtField.text forKey:@"phone"];
    
    return dict;
    
}

//TEXT FIELD DELEGATES
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.center.y>200 && showKeyboardAnimation) {
        CGPoint MyPoint = self.view.center;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             
                             self.view.center = CGPointMake(MyPoint.x, MyPoint.y - textField.center.y + 130);
                         }];
        
        showKeyboardAnimation=false;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
    if (showKeyboardAnimation) {
        //CGPoint MyPoint = self.view.center;
        
        [UIView animateWithDuration:0.3
                         animations:^{
                             
                             self.view.center = CGPointMake(viewCenter.x, viewCenter.y);
                         }];
        
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    showKeyboardAnimation = true;
    [self.view endEditing:YES];
}

- (IBAction)saveDetailsButtonTapped:(id)sender {
    _saveDetailsButton.selected = !_saveDetailsButton.isSelected;
    NSMutableDictionary* saveDetailsDict = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"SavedUserDetails"]];
    if (saveDetailsDict.count>0 && _saveDetailsButton.isSelected) {
        _firstNameTxtField.text = [saveDetailsDict valueForKey:@"firstName"];
        _lastNameTxtField.text = [saveDetailsDict valueForKey:@"lastName"];
        _emailTxtField.text = [saveDetailsDict valueForKey:@"email"];
        _phoneTxtField.text = [saveDetailsDict valueForKey:@"phone"];
    }
}
@end
