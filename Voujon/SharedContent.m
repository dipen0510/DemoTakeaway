//
//  SharedContent.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 02/04/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "SharedContent.h"

@implementation SharedContent

@synthesize cartArr,appSettingsDict,deliveryTimingArr,collectionTimingArr,orderDetailsDict, CurrentViewController, PaypalEmail, emailMsg,stripeToken, StripePublishKey, PaypalSecretKey,extraDistanceDeliveryCharge,extraDistanceInMiles,isRestoOpen;

static SharedContent *sharedObject = nil;

+ (id) sharedInstance
{
    if (! sharedObject) {
        
        sharedObject = [[SharedContent alloc] init];
    }
    return sharedObject;
}


@end
