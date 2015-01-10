//
//  IrregularButton.h
//  IrregularButton
//
//  Created by Jakey on 15/1/10.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^TouchedBlock)(NSInteger tag);

@interface IrregularButton : UIButton
{
    TouchedBlock _touchHandler;
}
-(void)addActionHandler:(TouchedBlock)touchHandler;
@end

@interface UIImage (Color)
- (UIColor *)colorAtPixel:(CGPoint)point;
- (UIImage *)edgeDetection;
@end