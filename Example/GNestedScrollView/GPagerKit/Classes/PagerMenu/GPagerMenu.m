//
//  GPagerMenu.m
//  GPagerKitExample
//
//  Created by GIKI on 2019/10/15.
//  Copyright © 2019 GIKI. All rights reserved.
//

#import "GPagerMenu.h"
#import "GPagerMenuInternal.h"
@interface GPagerMenu ()
@property (nonatomic, strong) UIImageView * divideLine;
@end

@implementation GPagerMenu

- (void)__setup
{
    self.selectItemScale = 1;
    [super __setup];
}

- (UIImageView *)divideLine
{
    if (!_divideLine) {
        _divideLine = [[UIImageView alloc] init];
        _divideLine.backgroundColor = [UIColor redColor];
        [self.scrollView addSubview:_divideLine];
        _divideLine.layer.cornerRadius = 2;
        _divideLine.layer.masksToBounds = YES;
    }
    return _divideLine;
}

- (void)switchPagerMenu:(NSInteger)index
{
    
}

- (void)__didselectItemAtIndex:(NSUInteger)index
{
    GPagerMenuLayoutInternal * layout = [self menuLayoutAtIndex:index];
    CGRect rect = layout.itemView.frame;
    self.divideLine.frame = CGRectMake(rect.origin.x+(rect.size.width-20)*0.5, CGRectGetMaxY(self.scrollView.frame)-4, 20, 4);
    [UIView animateWithDuration:0.25 animations:^{
        layout.itemView.transform = CGAffineTransformMakeScale(self.selectItemScale, self.selectItemScale);
    }];
}

- (void)__deselectItemAtIndex:(NSUInteger)index
{
     GPagerMenuLayoutInternal * layout = [self menuLayoutAtIndex:index];
     layout.itemView.transform = CGAffineTransformIdentity;
}

- (CGSize)__itemSizeAtIndex:(NSUInteger)index
{
    return CGSizeZero;
}

- (CGFloat)__itemSpacingAtIndex:(NSUInteger)index
{
    return 0;
}

@end
