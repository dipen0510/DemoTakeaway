//
//  AlertViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 13/09/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlertViewController : UIViewController

@property (strong, nonatomic) NSString* txt;

@property (weak, nonatomic) IBOutlet UILabel *alertLbl;
@end
