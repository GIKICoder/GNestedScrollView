//
//  DouyinProfileHeaderView.m
//  GStackScrollView_Example
//
//  Created by GIKI on 2024/8/5.
//  Copyright © 2024 GIKI. All rights reserved.
//

#import "DouyinProfileHeaderView.h"
#import "Masonry.h"
@interface DouyinProfileHeaderView ()
@property (nonatomic, strong) UIImageView * avatar;
@property (nonatomic, strong) UILabel * nameLabel;
@property (nonatomic, strong) UILabel * accountLabel;
@property (nonatomic, strong) UIView * borderView;
@end

@implementation DouyinProfileHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        
        [self addSubview:({
            UIImageView * imageView = [UIImageView new];
            imageView.layer.cornerRadius = 30;
            imageView.layer.masksToBounds = YES;
            imageView.layer.borderColor = UIColor.whiteColor.CGColor;
            imageView.layer.borderWidth = 1;
            imageView.contentMode = UIViewContentModeScaleToFill;
            imageView.image = [UIImage imageNamed:@"avatar.jpg"];
            _avatar = imageView;
            imageView;
        })];
        
        UIView * center = [UIView new];
        [self addSubview:center];
        
        [center addSubview:({
            UILabel * label = [UILabel new];
            label.textColor = UIColor.whiteColor;
            label.font = [UIFont systemFontOfSize:22];
            label.textAlignment = NSTextAlignmentLeft;
            label.text = @"大熊看电影";
            _nameLabel = label;
            label;
        })];
        
        [center addSubview:({
            UILabel * label = [UILabel new];
            label.textColor = UIColor.whiteColor;
            label.font = [UIFont systemFontOfSize:16];
            label.textAlignment = NSTextAlignmentLeft;
            label.text = @"抖音号: 12312312321";
            _accountLabel = label;
            label;
        })];
        
        [self addSubview:({
            _borderView = [UIView new];
            _borderView.backgroundColor = UIColor.whiteColor;
            _borderView;
        })];
        
        [self.avatar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(60);
            make.left.mas_equalTo(20);
            make.top.mas_equalTo(120);
        }];
        [center mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.avatar.mas_right).mas_offset(10);
            make.centerY.mas_equalTo(self.avatar.mas_centerY);
            make.top.equalTo(self.nameLabel);
            make.bottom.equalTo(self.accountLabel);
        }];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(0);
            make.top.mas_equalTo(0);
        }];
        [self.accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(0);
            make.top.mas_equalTo(self.nameLabel.mas_bottom).mas_offset(5);
        }];
        
        [self.borderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.mas_equalTo(220-16);
            make.bottom.equalTo(self);
        }];
        
        UILabel *label1 = [[UILabel alloc] init];
        UILabel *label2 = [[UILabel alloc] init];
        UILabel *label3 = [[UILabel alloc] init];
        
        // 设置标签的文本、颜色和字体大小
        label1.text = @"247.5万获赞";
        label1.textColor = [UIColor blackColor];
        label1.font = [UIFont systemFontOfSize:16];
        
        label2.text = @"20关注";
        label2.textColor = [UIColor blackColor];
        label2.font = [UIFont systemFontOfSize:16];
        
        label3.text = @"29.1万粉丝";
        label3.textColor = [UIColor blackColor];
        label3.font = [UIFont systemFontOfSize:16];
        
        [self.borderView addSubview:label1];
        [self.borderView addSubview:label2];
        [self.borderView addSubview:label3];
        
        [label1 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.borderView.mas_top).offset(20);
            make.left.equalTo(self.borderView.mas_left).offset(12);
            make.height.mas_equalTo(20);
            make.width.mas_greaterThanOrEqualTo(0);
        }];
        
        [label2 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(label1.mas_top);
            make.left.equalTo(label1.mas_right).offset(10);
            make.height.mas_equalTo(20);
            make.width.mas_greaterThanOrEqualTo(0);
        }];
        
        [label3 mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(label1.mas_top);
            make.left.equalTo(label2.mas_right).offset(10);
            make.height.mas_equalTo(20);
            make.width.mas_greaterThanOrEqualTo(0);
        }];
        
        UILabel * desclabel = [UILabel new];
        desclabel.textColor = UIColor.blackColor;
        desclabel.font = [UIFont systemFontOfSize:15];
        desclabel.textAlignment = NSTextAlignmentLeft;
        desclabel.text = @"专注于讲述每一部\n你值得拥有的好故事";
        desclabel.numberOfLines = 0;
        [self.borderView addSubview:desclabel];
        [desclabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(12);
            make.top.mas_equalTo(label1.mas_bottom).mas_offset(10);
        }];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self addTopMasklayer:16 container:self.borderView];
}


- (void)addTopMasklayer:(CGFloat)radii container:(UIView*)container
{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect: container.bounds byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(radii,radii)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = container.bounds;
    maskLayer.path = maskPath.CGPath;
    container.layer.mask = maskLayer;
}
@end
