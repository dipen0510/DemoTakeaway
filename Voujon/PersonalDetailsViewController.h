//
//  PersonalDetailsViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PersonalDetailsViewController : UIViewController<UITextFieldDelegate>
- (IBAction)backButtonTapped:(id)sender;
- (IBAction)nextButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTxtField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTxtField;
@property (weak, nonatomic) IBOutlet UITextField *emailTxtField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTxtField;
@property (weak, nonatomic) IBOutlet UIButton *saveDetailsButton;
- (IBAction)saveDetailsButtonTapped:(id)sender;

@end
