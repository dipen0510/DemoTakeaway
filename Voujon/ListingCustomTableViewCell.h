//
//  ListingCustomTableViewCell.h
//  Voujon
//
//  Created by Gurbir Singh on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ListingCustomTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *ItemTitle;
@property (weak, nonatomic) IBOutlet UILabel *ItemPrice;
@property (weak, nonatomic) IBOutlet UILabel *ItemDescription;
@property (weak, nonatomic) IBOutlet UILabel *ItemOther;

@property (strong, nonatomic) IBOutlet UIButton *addArrowButton;
@property (strong, nonatomic) IBOutlet UITextField *variantTxtField;
@property (strong, nonatomic) IBOutlet UILabel *variantLbl;
@property (weak, nonatomic) IBOutlet UILabel *includingOptionsLbl;
@property (weak, nonatomic) IBOutlet UILabel *optionsPriceLbl;
@property (weak, nonatomic) IBOutlet UIButton *optionAddButton;

@end
