//
//  FindViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MODropAlertView.h"

@interface FindViewController : UIViewController<CLLocationManagerDelegate, UITextFieldDelegate, MODropAlertViewDelegate>
{
    
    CLLocationManager* locationManager;
    BOOL isLocationForSecondTime;
    
    //Ashwani:: August 20 2015
    NSDictionary *dictRouteInfo;
    BOOL isVisible;
}

@property (weak, nonatomic) IBOutlet UITextField *fromTextField;
@property (weak, nonatomic) IBOutlet UITextField *toTextField;
@property (strong, nonatomic) IBOutlet MKMapView *findMapView;
@property (weak, nonatomic) IBOutlet UILabel *addressValLbl;
@property (weak, nonatomic) IBOutlet UILabel *phoneValLbl;

//Ashwani:: August 20 2015
//-(MKPolyline *)polylineWithEncodedString:(NSString *)encodedString ;
//-(void)addAnnotationSrcAndDestination :(CLLocationCoordinate2D )srcCord :(CLLocationCoordinate2D)destCord;
@property (nonatomic, retain) NSMutableArray *wayPoints;

- (IBAction)homeButtonTapped:(id)sender;

//-(void)showRouteFrom: (MKAnnotation*) f to:(MKAnnotation*) t;
@end
