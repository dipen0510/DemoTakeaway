//
//  AppDelegate.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Pushwoosh/PushNotificationManager.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,PushNotificationDelegate>
{
     NSDate *storedDate;
    
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navController;
@end

