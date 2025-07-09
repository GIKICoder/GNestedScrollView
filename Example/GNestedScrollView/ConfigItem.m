//
//  ConfigItem.m
//  GStackScrollView_Example
//
//  Created by GIKI on 2024/8/5.
//  Copyright © 2024 GIKI. All rights reserved.
//

#import "ConfigItem.h"

@implementation ConfigItem
- (instancetype)initWithTitle:(NSString *)title action:(ConfigItemAction)action {
    self = [super init];
    if (self) {
        _title = title;
        _action = action;
    }
    return self;
}

@end
