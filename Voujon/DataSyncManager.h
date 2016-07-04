//
//  DataSyncManager.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/04/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "AppDelegate.h"
#import "AFNetworking.h"

@protocol DataSyncManagerDelegate <NSObject>

-(void) didFinishServiceWithSuccess:(NSMutableDictionary *)responseData andServiceKey:(NSString *)requestServiceKey;
-(void) didFinishServiceWithFailure:(NSString *)errorMsg;

@end

@interface DataSyncManager : NSObject

@property (nonatomic,assign)  id <DataSyncManagerDelegate> delegate;
@property (nonatomic, strong) NSString* serviceKey;

-(void)startGETWebServicesWithBaseURL;
-(void)startPOSTWebServicesWithData:(id)postData;

@end
