//
//  OrderDetailsAlertViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 20/10/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MZFormSheetController.h"
#import "MZFormSheetSegue.h"

@interface OrderDetailsAlertViewController : UIViewController

@property (strong, nonatomic) NSString* txt;

@property (weak, nonatomic) IBOutlet UILabel *alertLbl;
- (IBAction)backToOrderButtonTapped:(id)sender;

@end
