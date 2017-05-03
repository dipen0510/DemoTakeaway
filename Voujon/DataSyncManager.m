//
//  DataSyncManager.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 01/04/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "DataSyncManager.h"

@implementation DataSyncManager
@synthesize delegate,serviceKey;


-(void)startGETWebServicesWithBaseURL
{
    NSURL* url;
    url = [NSURL URLWithString:WebServiceURL];
    
    NSLog(@"Service URl::%@/%@",url,self.serviceKey);
    //NSError *theError = nil;
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.requestSerializer setValue:@"MyAwsomeWWKey" forHTTPHeaderField:@"API-KEY"];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/xml"];
    
    
    [manager GET:self.serviceKey parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //NSLog(@"Response %@",responseObject);
        
        NSData * data = (NSData *)responseObject;
        NSString *fetchedXML = [NSString stringWithCString:[data bytes] encoding:NSISOLatin1StringEncoding];
        
        if (fetchedXML && ![fetchedXML isEqualToString:@""]) {
            
            NSData *objectData = [fetchedXML dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
            dict = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:nil];
            
            if ([[dict valueForKey:@"Status"] isEqualToString:@"Success"]) {
                [delegate didFinishServiceWithSuccess:dict andServiceKey:self.serviceKey];

            }
            else {
                [delegate didFinishServiceWithFailure:@"Response not appropriate. Please try again later."];
            }
            
        }
        else {
            [delegate didFinishServiceWithFailure:@"An issue occured. Please try again later."];
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [delegate didFinishServiceWithFailure:@"Please check your internet connection and try again later"];
       
    }];
    
}


-(void)startPOSTWebServicesWithData:(id)postData
{
    
    NSURL* url;
    url = [NSURL URLWithString:WebServiceURL];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager.requestSerializer setValue:@"MyAwsomeKey" forHTTPHeaderField:@"API-KEY"];
    [manager POST:self.serviceKey parameters:(id)postData success:^(NSURLSessionDataTask *task, id responseObject) {
            
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                
                if ([[responseObject valueForKey:@"Status"] isEqualToString:@"Success"]) {
                    [delegate didFinishServiceWithSuccess:(NSMutableDictionary *)responseObject andServiceKey:self.serviceKey];
                }
                else {
                    [delegate didFinishServiceWithFailure:[[responseObject valueForKey:@"error"] valueForKey:@"message"]];
                }
                
                
            }
            else {
                [delegate didFinishServiceWithFailure:@"Unexpected network error"];
            }
    }
          failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [delegate didFinishServiceWithFailure:@"Please check your internet connection and try again later"];
        
    }];
    
}





-(void)startPOSTWebServicesForStripeWithData:(id)postData
{
    
    NSURL* url;
    url = [NSURL URLWithString:@"http://rhitapi.co.uk/api/stripe"];
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    manager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    [manager POST:self.serviceKey parameters:(id)postData success:^(NSURLSessionDataTask *task, id responseObject) {
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            
            if ([[responseObject valueForKey:@"Status"] isEqualToString:@"Success"]) {
                [delegate didFinishServiceWithSuccess:(NSMutableDictionary *)responseObject andServiceKey:self.serviceKey];
            }
            else {
                [delegate didFinishServiceWithFailure:[[responseObject valueForKey:@"error"] valueForKey:@"message"]];
            }
            
            
        }
        else {
            [delegate didFinishServiceWithFailure:@"Unexpected network error"];
        }
    }
          failure:^(NSURLSessionDataTask *task, NSError *error) {
              
              [delegate didFinishServiceWithFailure:@"Please check your internet connection and try again later"];
              
          }];
    
}




-(void)startStripePaymentChargeWithParams:(NSMutableDictionary *)postData
{
    
    NSURL* url;
    url = [NSURL URLWithString:@"https://api.stripe.com/v1"];
    
    NSString* secretKey = @"sk_test_1oViCmIXkXtDQykknqLQZt1p";
    
    if (![[[SharedContent sharedInstance] StripeSecretKey] isEqualToString:@""] && [[SharedContent sharedInstance] StripeSecretKey]) {
        secretKey = [[SharedContent sharedInstance] StripeSecretKey];
    }
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    
    [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@",secretKey] forHTTPHeaderField:@"Authorization"];
//    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:secretKey password:@""];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    [manager POST:self.serviceKey parameters:postData success:^(NSURLSessionTask *task, id responseObject) {
        
        //if ([responseObject isKindOfClass:[NSDictionary class]]) {
        
        if ([[responseObject valueForKey:@"status"] isEqualToString:@"succeeded"]) {
            
            if ([delegate respondsToSelector:@selector(didFinishServiceWithSuccess:andServiceKey:)]) {
                [delegate didFinishServiceWithSuccess:nil andServiceKey:self.serviceKey];
            }
        }
        else {
            //if ([delegate respondsToSelector:@selector(didFinishServiceWithFailure:)]) {
            [delegate didFinishServiceWithFailure:[responseObject valueForKey:@"msg"]];
            //}
            
        }
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        if ([delegate respondsToSelector:@selector(didFinishServiceWithFailure:)]) {
            [delegate didFinishServiceWithFailure:NSLocalizedString(@"Verify your internet connection and try again", nil)];
        }
        
        
    }];
    
    
}


@end
