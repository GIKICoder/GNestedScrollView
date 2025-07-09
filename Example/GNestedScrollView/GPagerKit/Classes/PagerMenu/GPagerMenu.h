//
//  GPagerMenu.h
//  GPagerKitExample
//
//  Created by GIKI on 2019/10/15.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GBasePagerMenu.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GPagerMenuStyle) {
    GPagerMenuStyleNone,
    GPagerMenuStyleLine,
    GPagerMenuStyleRect,
};

@interface GPagerMenu : GBasePagerMenu

@property (nonatomic, assign) GPagerMenuStyle  menuStyle;
@property (nonatomic, assign) CGFloat    selectItemScale;

- (void)switchPagerMenu:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
