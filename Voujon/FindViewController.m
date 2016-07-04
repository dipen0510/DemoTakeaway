//
//  FindViewController.m
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import "FindViewController.h"

#define IS_iOS8_0_OR_LATER (([[[UIDevice currentDevice] systemName] isEqualToString:@"iOS"] || [[[UIDevice currentDevice] systemName] isEqualToString:@"iPhone OS"]) && [[[[UIDevice currentDevice] systemVersion] substringToIndex:1] intValue] >= 8)

//Ashwani :: Google map api
#define kBaseUrl @"http://maps.googleapis.com/maps/api/directions/json?"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0)

@interface FindViewController ()
//-(NSArray*) calculateRoutesFrom:(CLLocationCoordinate2D) from to: (CLLocationCoordinate2D) to;
//-(void) centerMap;
@end

@implementation FindViewController
//@synthesize
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    locationManager = [[CLLocationManager alloc] init];
    if (IS_iOS8_0_OR_LATER) {
        [locationManager requestWhenInUseAuthorization];
    }
    
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    
    [self.findMapView setShowsUserLocation:true];
    
    self.fromTextField.text = @"Current Location";
    
    NSDictionary* dict = [[NSDictionary alloc] initWithDictionary:[[SharedContent sharedInstance] appSettingsDict]];
    
    self.toTextField.text = [dict valueForKey:@"Postcode"];
    
    self.addressValLbl.text = [NSString stringWithFormat:@"%@, %@, %@, %@",[dict valueForKey:@"AddressLine1"],[dict valueForKey:@"City"],[dict valueForKey:@"County"],[dict valueForKey:@"Postcode"]];
    self.phoneValLbl.text = [dict valueForKey:@"Phone"];
    
    _wayPoints = [[NSMutableArray alloc] init];
    //[self getLatLong];
    
    MKCoordinateSpan theSpan = MKCoordinateSpanMake(0.15, 0.15);
    MKCoordinateRegion theRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake([[dict valueForKey:@"Latitude"] floatValue] ,[[dict valueForKey:@"Longitude"] floatValue]), theSpan);
    [self.findMapView setRegion:theRegion animated:true];
    
    
}

/*-(void)findPath:(id)sender
{
    [self getLatLong];
}

//Ashwani :: August 20, Get lat long
-(void)getLatLong
{
    
    if(self.fromTextField.text == nil || [self.fromTextField.text isEqualToString:@""])
    {
        [self showAlert:@"Choose Source Location ?"];
        return;
    }
    
    if(self.toTextField.text == nil || [self.toTextField.text isEqualToString:@""])
    {
        [self showAlert:@"Choose Destination Location ?"];
        return;
    }
    
    [self.findMapView removeOverlays:self.findMapView.overlays];
    [self.findMapView removeAnnotations:self.findMapView.annotations];
    
    dispatch_async(kBgQueue, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSString *strUrl;
        strUrl=[NSString stringWithFormat:@"%@origin=%@&destination=%@&sensor=true",kBaseUrl,self.fromTextField.text,self.toTextField.text];
        
        NSLog(@"%@",strUrl);
        strUrl=[strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData *data =[NSData dataWithContentsOfURL:[NSURL URLWithString:strUrl]];
        
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}

#pragma mark - json parser
- (void)fetchedData:(NSData *)responseData {
    NSError* error;
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData //1
                          
                          options:kNilOptions
                          error:&error];
    NSArray *arrRouts=[json objectForKey:@"routes"];
    if ([arrRouts isKindOfClass:[NSArray class]]&&arrRouts.count==0) {
        UIAlertView *alrt=[[UIAlertView alloc]initWithTitle:@"Alert" message:@"didn't find direction" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [alrt show];
        return;
    }
    NSArray *arrDistance =[[[json valueForKeyPath:@"routes.legs.steps.distance.text"] objectAtIndex:0]objectAtIndex:0];
    NSString *totalDuration = [[[json valueForKeyPath:@"routes.legs.duration.text"] objectAtIndex:0]objectAtIndex:0];
    NSString *totalDistance = [[[json valueForKeyPath:@"routes.legs.distance.text"] objectAtIndex:0]objectAtIndex:0];
    NSArray *arrDescription =[[[json valueForKeyPath:@"routes.legs.steps.html_instructions"] objectAtIndex:0] objectAtIndex:0];
    dictRouteInfo=[NSDictionary dictionaryWithObjectsAndKeys:totalDistance,@"totalDistance",totalDuration,@"totalDuration",arrDistance ,@"distance",arrDescription,@"description", nil];
    
    NSArray* arrpolyline = [[[json valueForKeyPath:@"routes.legs.steps.polyline.points"] objectAtIndex:0] objectAtIndex:0]; //2
    double srcLat=[[[[json valueForKeyPath:@"routes.legs.start_location.lat"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    double srcLong=[[[[json valueForKeyPath:@"routes.legs.start_location.lng"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    double destLat=[[[[json valueForKeyPath:@"routes.legs.end_location.lat"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    double destLong=[[[[json valueForKeyPath:@"routes.legs.end_location.lng"] objectAtIndex:0] objectAtIndex:0] doubleValue];
    CLLocationCoordinate2D sourceCordinate = CLLocationCoordinate2DMake(srcLat, srcLong);
    CLLocationCoordinate2D destCordinate = CLLocationCoordinate2DMake(destLat, destLong);
    
    [self addAnnotationSrcAndDestination:sourceCordinate :destCordinate];
    //    NSArray *steps=[[aary objectAtIndex:0]valueForKey:@"steps"];
    
    //    replace lines with this may work
    
    NSMutableArray *polyLinesArray =[[NSMutableArray alloc]initWithCapacity:0];
    
    for (int i = 0; i < [arrpolyline count]; i++)
    {
        NSString* encodedPoints = [arrpolyline objectAtIndex:i] ;
        MKPolyline *route = [self polylineWithEncodedString:encodedPoints];
        [polyLinesArray addObject:route];
    }
    
    [self.findMapView addOverlays:polyLinesArray];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - add annotation on source and destination

-(void)addAnnotationSrcAndDestination :(CLLocationCoordinate2D )srcCord :(CLLocationCoordinate2D)destCord
{
    MKPointAnnotation *sourceAnnotation = [[MKPointAnnotation alloc]init];
    MKPointAnnotation *destAnnotation = [[MKPointAnnotation alloc]init];
    sourceAnnotation.coordinate=srcCord;
    destAnnotation.coordinate=destCord;
    sourceAnnotation.title = self.fromTextField.text;
    
    destAnnotation.title = self.toTextField.text;
    
    [self.findMapView addAnnotation:sourceAnnotation];
    [self.findMapView addAnnotation:destAnnotation];
    
    MKCoordinateRegion region;
    
    MKCoordinateSpan span;
    span.latitudeDelta=2;
    span.latitudeDelta=2;
    region.center=srcCord;
    region.span=span;
    CLGeocoder *geocoder= [[CLGeocoder alloc]init];
    for (NSString *strVia in _wayPoints) {
        [geocoder geocodeAddressString:strVia completionHandler:^(NSArray *placemarks, NSError *error) {
            if ([placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                CLLocation *location = placemark.location;
                //                CLLocationCoordinate2D coordinate = location.coordinate;
                MKPointAnnotation *viaAnnotation = [[MKPointAnnotation alloc]init];
                viaAnnotation.coordinate=location.coordinate;
                [self.findMapView addAnnotation:viaAnnotation];
                //                NSLog(@"%@",placemarks);
            }
            
        }];
    }
    
    self.findMapView.region=region;
}

#pragma mark - decode map polyline

- (MKPolyline *)polylineWithEncodedString:(NSString *)encodedString {
    const char *bytes = [encodedString UTF8String];
    NSUInteger length = [encodedString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger idx = 0;
    
    NSUInteger count = length / 4;
    CLLocationCoordinate2D *coords = calloc(count, sizeof(CLLocationCoordinate2D));
    NSUInteger coordIdx = 0;
    
    float latitude = 0;
    float longitude = 0;
    while (idx < length) {
        char byte = 0;
        int res = 0;
        char shift = 0;
        
        do {
            byte = bytes[idx++] - 63;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLat = ((res & 1) ? ~(res >> 1) : (res >> 1));
        latitude += deltaLat;
        
        shift = 0;
        res = 0;
        
        do {
            byte = bytes[idx++] - 0x3F;
            res |= (byte & 0x1F) << shift;
            shift += 5;
        } while (byte >= 0x20);
        
        float deltaLon = ((res & 1) ? ~(res >> 1) : (res >> 1));
        longitude += deltaLon;
        
        float finalLat = latitude * 1E-5;
        float finalLon = longitude * 1E-5;
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(finalLat, finalLon);
        coords[coordIdx++] = coord;
        
        if (coordIdx == count) {
            NSUInteger newCount = count + 10;
            coords = realloc(coords, newCount * sizeof(CLLocationCoordinate2D));
            count = newCount;
        }
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:coordIdx];
    free(coords);
    
    return polyline;
}
#pragma mark - map overlay
- (MKOverlayView *)mapView:(MKMapView *)mapView
            viewForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineView *overlayView = [[MKPolylineView alloc] initWithOverlay:overlay];
    overlayView.lineWidth = 6;
    overlayView.strokeColor = [UIColor redColor];
    overlayView.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.1f];
    return overlayView;
    
}

#pragma mark - map annotation
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if (annotation==self.findMapView.userLocation) {
        return nil;
    }
    static NSString *annotaionIdentifier=@"annotationIdentifier";
    MKPinAnnotationView *aView=(MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotaionIdentifier ];
    if (aView==nil) {
        
        aView=[[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:annotaionIdentifier];
        aView.pinColor = MKPinAnnotationColorRed;
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        //        aView.image=[UIImage imageNamed:@"arrow"];
        aView.animatesDrop=TRUE;
        aView.canShowCallout = YES;
        aView.calloutOffset = CGPointMake(-5, 5);
    }
    
    return aView;
}


#pragma mark - Text Field Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if((textField.text == nil || [textField.text isEqualToString:@""]) && textField.tag == 0)
    {
        [self.findMapView removeOverlays:self.findMapView.overlays];
        [self.findMapView removeAnnotations:self.findMapView.annotations];
        [self showAlert:@"Choose Source Location ?"];
        return YES;
    }
    else if((textField.text == nil || [textField.text isEqualToString:@""]) && textField.tag == 1)
    {
        [self.findMapView removeOverlays:self.findMapView.overlays];
        [self.findMapView removeAnnotations:self.findMapView.annotations];
        [self showAlert:@"Choose Destination Location ?"];
        return YES;
    }
    else
        [self getLatLong];
    return YES;
}


#pragma mark - Alert View -
-(void)showAlert:(NSString *)msg
{
    MODropAlertView *alertView = [[MODropAlertView alloc]initDropAlertWithTitle:@"Voujon Message"
                                                                    description:msg
                                                                  okButtonTitle:@"OK"
                                                              cancelButtonTitle:nil];
    alertView.delegate = self;
    [alertView show];
}

#pragma mark custom alert delegates
- (void)alertViewPressButton:(MODropAlertView *)alertView buttonType:(DropAlertButtonType)buttonType
{
    [alertView dismiss];
}

- (void)alertViewWillAppear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}
- (void)alertViewDidAppear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)alertViewWilldisappear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)alertViewDidDisappear:(MODropAlertView *)alertView
{
    //NSLog(@"%s", __FUNCTION__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
*/

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    //CLLocationCoordinate2D currentLocation;
    if (!isLocationForSecondTime) {
        //[self.fromTextField setText:[NSString stringWithFormat:@"%f, %f",newLocation.coordinate.latitude,newLocation.coordinate.longitude]];
        isLocationForSecondTime = YES;
        
        
        
        NSLog(@"Current Location : Lat %f, Long %f",newLocation.coordinate.latitude,newLocation.coordinate.longitude);
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



- (IBAction)homeButtonTapped:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

@end
