//
//  ConfigItem.h
//  GStackScrollView_Example
//
//  Created by GIKI on 2024/8/5.
//  Copyright © 2024 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ConfigItemAction)(void);

@interface ConfigItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, copy) ConfigItemAction action;

- (instancetype)initWithTitle:(NSString *)title action:(ConfigItemAction)action;

@end

NS_ASSUME_NONNULL_END
