//
//  OrderViewController.h
//  Voujon
//
//  Created by Dipen Sekhsaria on 19/08/15.
//  Copyright (c) 2015 Dipen Sekhsaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ListingCustomTableViewCell.h"
#import "AlertViewController.h"

@interface OrderViewController : UIViewController<DataSyncManagerDelegate,UIPickerViewDataSource,UIPickerViewDelegate,UITextFieldDelegate , UIGestureRecognizerDelegate>
{
    UIView *view;
    NSString *selectedCategory;
    BOOL IsSearch;
    
    NSMutableArray *categoryArr;
    NSMutableArray *menuDisplayArr;
    NSIndexPath* expandedIndexPath;
    
    NSMutableArray* variantArr;
    NSMutableDictionary* selectedPickerContent;
    
    NSMutableArray* strengthArr;
    NSString* selectedStrengthPickerContent;
    
    
    UIPickerView* picker;
    UIPickerView* strengthPicker;
    UIPickerView* prodOptionPicker;
    
    //Ashwani :: Custom data Array
    NSMutableArray* componentItemArr, *selctedArrItems;
    NSString *selectedComponentID, *strOptionSelected, *selectedProdCompID;
    NSMutableArray* selectedComponentPickerContent;
    UIButton *componentPickerDoneButton, *prodOptionPickerDoneButton;
    
    NSMutableArray* prodOptionsArr, *prodOptionsItemArr, *selectedProdOptArr, *pickerOptArr;
    NSMutableDictionary* selectedprodOptionsPickerContent;
    BOOL isSetMealView;
    UIPickerView *picker1;
    
    BOOL alertType;
    
    NSMutableArray *selectedItems;// will hold the selected values for multi select picker
    UITableView *tableViewPicker;
    UIView *viewHeader;
    NSMutableArray *arraySelect;
    int maxselect, minselect, *minItemSelection;
    
    //Ashwani :: Use this for offers checking price
    BOOL IsOfferPriceZero, IsItemSelectionAllow;
    //Ashwani :: this price will be use if any offer discount exist
    NSString *AbsolutePrice, *RelativePrice;
    //Ashwani ::
    
    UITableView *tableViewOptPicker, *tableViewVoujonPicker;
    NSMutableArray *selectedOptItems;
    NSMutableArray* arrSelectedprodOptionsPickerContent;
    
    //Ashwani :: Take a string to save component id to show dropdown on the behalf of productcomponentid
    NSString *selectedComponentIdForOffer, *strOptionId;
    
    //Ashwani :: To show further topping for sub products , use these arrays and dictionary
    NSMutableArray *arrToppings,*selectedToppings, *toppingPickerOptionArray;
    UIView *customView1, *customView2, *viewToppingHeader;
    CGFloat DeviceWidth, DeviceHeight;
    UITableView *tblToppingPicker, *tblToppingPickerForStandard;
    UIButton *ToppingDoneButtonTapped;
    
    
    //Ashwani :: This array will use to check the item selection is done or not, we will add button tag in it to check the text contains on it
    NSMutableArray *arrButtonTags;
    
    //Ashwani:: These variable will be used to check the minimun and maximum selection of product items and their toppings
    int MinSelectItems,MaxSelectItems, MinSelectToppings, MaxSelectToppings;
    NSMutableDictionary *selectedDict;
    UILabel *lblOfferCount;
    
    int SelOfferIndex, SelVariantIndex, selToppingIndex;
    UIButton *btnVarient, *DonePickerButton;
    UIPickerView *variantPicker;
    UIToolbar *toolBar;
    
    UITableView *tblOfferVarients;
    
    NSMutableArray *selOfferVariants, *selVariants, *selOfferToppings, *selToppings;
    NSMutableDictionary *offerDict, *compToppings;
    
    UIScrollView *scrollView;
}
@property (weak, nonatomic) IBOutlet UIView *categoryMenuView;
@property (weak, nonatomic) IBOutlet UITableView *orderMenuTblView;
@property (strong, nonatomic) IBOutlet UIButton *checkoutButton;
@property (strong, nonatomic) IBOutlet UILabel *orderPriceLbl;

- (IBAction)categoryButtonTapped:(id)sender;
- (IBAction)homeButtonTapped:(id)sender;
- (IBAction)checkOutButtonTapped:(id)sender;

@end
