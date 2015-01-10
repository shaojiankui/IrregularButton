//
//  IrregularButton.m
//  IrregularButton
//
//  Created by Jakey on 15/1/10.
//  Copyright (c) 2015年 www.skyfox.org. All rights reserved.
//
#define AlphaVisible (0.1f)

#import "IrregularButton.h"
#import <Accelerate/Accelerate.h>
@implementation IrregularButton
-(void)addActionHandler:(TouchedBlock)touchHandler{
    if (touchHandler) {
        _touchHandler = [touchHandler copy];
        [self addTarget:self action:@selector(actionTouched:) forControlEvents:UIControlEventTouchUpInside];
    }
}
-(void)actionTouched:(UIButton *)btn{
    if (_touchHandler) {
        _touchHandler(btn.tag);
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // Return NO if even super returns NO (i.e., if point lies outside our bounds)
    BOOL superResult = [super pointInside:point withEvent:event];
    if (!superResult) {
        return superResult;
    }
    
    if (![self currentImage] && ![self currentBackgroundImage]) {
        return  YES;
    }
    
    if ([self currentImage] && ![self currentBackgroundImage]) {
        
        return [self vaildAtPoint:point forImage:[self currentImage]];
    }
    
    if ([self currentBackgroundImage] && ![self currentImage]) {
        
        return  [self vaildAtPoint:point forImage:[self currentBackgroundImage]];
    }
    
    BOOL result;

    if ([self currentBackgroundImage] && [self currentImage]) {
        if ([self vaildAtPoint:point forImage:[self currentImage]]) {
            result = YES;
        } else {
            result = [self vaildAtPoint:point forImage:[self currentBackgroundImage]];
        }
    }

    
    return result;

}

- (BOOL)vaildAtPoint:(CGPoint)point forImage:(UIImage *)image
{
    // Correct point to take into account that the image does not have to be the same size
    // as the button. See https://github.com/ole/OBShapedButton/issues/1
    CGSize iSize = image.size;
    CGSize bSize = self.bounds.size;
    point.x *= (bSize.width != 0) ? (iSize.width / bSize.width) : 1;
    point.y *= (bSize.height != 0) ? (iSize.height / bSize.height) : 1;
    UIColor *pixelColor = [image colorAtPixel:point];
    
    CGFloat alpha = 0.0;
    if ([pixelColor respondsToSelector:@selector(getRed:green:blue:alpha:)])
    {
        // available from iOS 5.0
        [pixelColor getRed:NULL green:NULL blue:NULL alpha:&alpha];
    }
    else
    {
        // for iOS < 5.0
        // In iOS 6.1 this code is not working in release mode, it works only in debug
        // CGColorGetAlpha always return 0.
        CGColorRef cgPixelColor = [pixelColor CGColor];
        alpha = CGColorGetAlpha(cgPixelColor);
    }
    NSLog(@"alpha%f",alpha);
    return alpha >= AlphaVisible;
}

@end


@implementation UIImage (Color)
- (UIColor *)colorAtPixel:(CGPoint)point
{
    // Cancel if point is outside image coordinates
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), point)) {
        return nil;
    }
    
    // Create a 1x1 pixel byte array and bitmap context to draw the pixel into.
    // Reference: http://stackoverflow.com/questions/1042830/retrieving-a-pixel-alpha-value-for-a-uiimage
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    CGImageRef cgImage = self.CGImage;
    NSUInteger width = self.size.width;
    NSUInteger height = self.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 1,
                                                 1,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    // Draw the pixel we are interested in onto the bitmap context
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    // Convert color values [0..255] to floats [0.0..1.0]
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}
static int16_t edgedetect_kernel[9] = {
    -1, -1, -1,
    -1, 8, -1,
    -1, -1, -1
};

static uint8_t backgroundColorBlack[4] = {0,0,0,0};

- (UIImage *)edgeDetection
{
    const size_t width = self.size.width;
    const size_t height = self.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext)
        return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, self.CGImage);
    UInt8* data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data)
    {
        CGContextRelease(bmContext);
        return nil;
    }
    const size_t n = sizeof(UInt8) * width * height * 4;
    void* outt = malloc(n);
    vImage_Buffer src = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {outt, height, width, bytesPerRow};
    vImageConvolve_ARGB8888(&src, &dest, NULL, 0, 0, edgedetect_kernel, 3, 3, 1, backgroundColorBlack, kvImageCopyInPlace);
    memcpy(data, outt, n);
    CGImageRef edgedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage* edged = [UIImage imageWithCGImage:edgedImageRef];
    CGImageRelease(edgedImageRef);
    free(outt);
    CGContextRelease(bmContext);
    return edged;
}
@end
