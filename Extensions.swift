
//
//  Extensions.swift
//  test_yandex_weather
//
//  Created by Test on 9/27/15.
//  Copyright © 2015 Test. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func imageByBestFitForSize (targetSize: CGSize) -> UIImage {
        
        let aspectRatio = self.size.width / self.size.height
        let targetHeight = targetSize.height
        let scaledWidth = targetSize.height * aspectRatio
        let targetWidth = min(targetSize.width, scaledWidth)
        return imageByScalingAndCroppingForSize(CGSizeMake(targetWidth, targetHeight))
    }
    
    func imageByScalingAndCroppingForSize (targetSize: CGSize) -> UIImage {
        
        let sourceImage = self
        let imageSize = sourceImage.size
        let width = imageSize.width
        let height = imageSize.height
        let targetWidth = targetSize.width
        let targetHeight = targetSize.height
        var scaleFactor = CGFloat(0.0)
        var scaledWidth = targetWidth
        var scaledHeight = targetHeight
        var thumbnailPoint = CGPointMake(0.0,0.0)
        
        if (CGSizeEqualToSize(imageSize, targetSize) == false) {
            let widthFactor = targetWidth / width
            let heightFactor = targetHeight / height
            if widthFactor > heightFactor {
                scaleFactor = widthFactor
            } else {
                scaleFactor = heightFactor
                scaledWidth  = ceil(width * scaleFactor)
                scaledHeight = ceil(height * scaleFactor)
            }
            if (widthFactor > heightFactor) {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            } else {
                if (widthFactor < heightFactor) {
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
                }
            }
        }
        
        UIGraphicsBeginImageContext(targetSize);
        var thumbnailRect = CGRectZero;
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width  = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        sourceImage.drawInRect(thumbnailRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}