//
//  AppDelegate.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "AppDelegate.h"
#import <Stripe/Stripe.h>
#import <OneSignal/OneSignal.h>

@import CoreLocation;
@import SystemConfiguration;
@import AVFoundation;
@import ImageIO;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.navController = [[UINavigationController alloc] init];
    [self.navController.navigationBar setBackgroundColor:[UIColor colorWithRed:220.0f/255.0f green:0.0f/255.0f blue:19.0f/255.0f alpha:1.0f]];
    
    
    
    [[SharedContent sharedInstance] setCartArr:[[NSMutableArray alloc] init]];
    
    //Ashwani : : Final Key
//    [PayPalMobile initializeWithClientIdsForEnvironments:@{PayPalEnvironmentSandbox : @"AS0Q0Jy4KvM8QC2IANEoLtmH_amgBB_f-wYz6oa-NdKdriGjVp4Ysa6oFakPfvUOC94zCtd2V8xFSYAH"}];
    
    [Stripe setDefaultPublishableKey:@"pk_test_3Uvqk3cfNhYfDMvrqXt7rCEF"];
    
    [OneSignal initWithLaunchOptions:launchOptions appId:@"4235b4b8-d091-4a04-9e1d-77d30a0daa11"];
    
    return YES;
}


// system push notification registration success callback, delegate to pushManager
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
//    [[PushNotificationManager pushManager] handlePushRegistration:deviceToken];
}

// system push notification registration error callback, delegate to pushManager
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
//    [[PushNotificationManager pushManager] handlePushRegistrationFailure:error];
}

// system push notifications callback, delegate to pushManager
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
//    [[PushNotificationManager pushManager] handlePushReceived:userInfo];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    storedDate = [NSDate date];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    //Ashwani Nov02_2015 :: Check date when app become active
    
    NSDate *date1 = [NSDate date];
    NSDate* date2 = storedDate;
    NSTimeInterval distanceBetweenDates = [date1 timeIntervalSinceDate:date2];
    double minutesInAnHour = 60;
    NSInteger minutesBetweenDates = distanceBetweenDates / minutesInAnHour;
    NSLog(@"minutes are: %ld",(long)minutesBetweenDates);
    if(minutesBetweenDates > 20)
    {
        
        [SVProgressHUD showWithStatus:@"Session Expired, Please try again !"];
        
        [[SharedContent sharedInstance] setOrderDetailsDict:[[NSMutableDictionary alloc] init]];
        [[SharedContent sharedInstance] setCartArr:[[NSMutableArray alloc] init]];
        
        //Ashwani :: Local notification with this name "" thrown if session expired to pop all the comntrollers
        NSNotification * notification =[[ NSNotification alloc]
                                        initWithName:@"ViewController" object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        [SVProgressHUD dismiss];
        
    }
    //Ashwani :----------- END ------------------------------
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
