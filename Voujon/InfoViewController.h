//
//  InfoViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoViewController : UIViewController<UITableViewDataSource,UITableViewDelegate> {
    NSMutableArray* dayArr;
    NSMutableArray* deliveryTimingArr;
    NSMutableArray* collectionTimingArr;
}

@property (weak, nonatomic) IBOutlet UIScrollView *infoScrollView;
- (IBAction)homeButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *freeWithinValLbl;
@property (weak, nonatomic) IBOutlet UILabel *chargePerMileValLbl;
@property (weak, nonatomic) IBOutlet UILabel *deliveryTimeValLbl;
@property (weak, nonatomic) IBOutlet UILabel *macRadiusValLbl;
@property (weak, nonatomic) IBOutlet UILabel *lblCollectionTime;
@property (weak, nonatomic) IBOutlet UILabel *collectionTimeValLbl;

@property (weak, nonatomic) IBOutlet UIView *parentView;
@property (weak, nonatomic) IBOutlet UILabel *DiscountLabel;
@property (weak, nonatomic) IBOutlet UILabel *lblThreshold;
@property (weak, nonatomic) IBOutlet UILabel *lblFreeDeliveryThreshold;

@end
