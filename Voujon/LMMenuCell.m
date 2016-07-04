//
//  LMMenuCell.m
//  LMDropdownViewDemo
//
//  Created by LMinh on 16/07/2014.
//  Copyright (c) 2014 LMinh. All rights reserved.
//

#import "LMMenuCell.h"

@implementation LMMenuCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.menuItemLabel.backgroundColor = [UIColor lightGrayColor];
    }
    else {
        self.menuItemLabel.backgroundColor = [UIColor lightGrayColor];
    }
}

@end
