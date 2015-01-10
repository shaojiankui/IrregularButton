//
//  RootViewController.h
//  IrregularButton
//
//  Created by Jakey on 15/1/10.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IrregularButton.h"
@interface RootViewController : UIViewController
@property (weak, nonatomic) IBOutlet IrregularButton *button;

@property (weak, nonatomic) IBOutlet UIImageView *showImage;
@end
