//
//  SharedContent.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 02/04/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharedContent : NSObject

+ (id) sharedInstance;

@property (strong, nonatomic) NSMutableArray* cartArr;
@property (strong, nonatomic) NSDictionary* appSettingsDict;
@property (strong, nonatomic) NSMutableArray* deliveryTimingArr;
@property (strong, nonatomic) NSMutableArray* collectionTimingArr;
@property (strong, nonatomic) NSMutableDictionary* orderDetailsDict;

//Ashwani :: This string will be use to hole the class name
@property (strong, nonatomic) NSString *CurrentViewController;

//Ashwani :: Paypal email id save
@property (strong, nonatomic) NSString *PaypalEmail;

@property (strong, nonatomic) NSString *emailMsg;

@property (strong, nonatomic) NSString *stripeToken;

@property (strong, nonatomic) NSString *PaypalSecretKey;
@property (strong, nonatomic) NSString *StripePublishKey;

@property float extraDistanceInMiles;
@property float extraDistanceDeliveryCharge;

@property BOOL isRestoClosed;

@end
