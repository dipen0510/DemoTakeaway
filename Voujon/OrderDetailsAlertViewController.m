//
//  OrderDetailsAlertViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 20/10/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "OrderDetailsAlertViewController.h"

@interface OrderDetailsAlertViewController ()

@end

@implementation OrderDetailsAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    
    [self.alertLbl setText:self.txt];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)backToOrderButtonTapped:(id)sender {
    
    [self.formSheetController dismissAnimated:true completionHandler:nil];
    
}
@end
