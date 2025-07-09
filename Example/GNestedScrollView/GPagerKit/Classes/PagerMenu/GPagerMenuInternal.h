//
//  GPagerMenuInternal.h
//  GPagerKitExample
//
//  Created by GIKI on 2019/10/15.
//  Copyright © 2019 GIKI. All rights reserved.
//

#ifndef GPagerMenuInternal_h
#define GPagerMenuInternal_h
#import "GBasePagerMenu.h"

@interface GBasePagerMenu ()
{
    struct {
        //dataSource flags
        unsigned int ds_MenuItems;
        unsigned int ds_MenuItemAtIndex;
        unsigned int ds_MenuItemSizeAtIndex;
        unsigned int ds_MenuItemSpacingAtIndex;
        
        //delegate flags
        unsigned int dg_TapSelectAtIndex;
        unsigned int dg_DidHighlight;
        unsigned int dg_DidUnhighlight;        
    } _pagerMenuFlags;
}
@property (nonatomic, strong) NSArray<GPagerMenuLayoutInternal *> * menuLayouts;
- (void)__setup;
- (void)__didselectItemAtIndex:(NSUInteger)index;
- (void)__deselectItemAtIndex:(NSUInteger)index;
- (CGSize)__itemSizeAtIndex:(NSUInteger)index;
- (CGFloat)__itemSpacingAtIndex:(NSUInteger)index;
- (GPagerMenuLayoutInternal *)menuLayoutAtIndex:(NSInteger)index;
@end

@interface GPagerMenuLayoutInternal ()
@property (nonatomic, strong) UIView * itemView;
@property (nonatomic, assign) CGSize  itemSize;
@property (nonatomic, assign) CGFloat  itemSpace;
@end
#endif /* GPagerMenuInternal_h */
