//
//  CIImage.swift
//  
//
//  Created by Julian Kahnert on 06.11.20.
//

#if canImport(AppKit)
import AppKit
#else
import UIKit.UIImage
#endif

extension CIImage {
    func jpegData(compressionQuality quality: CGFloat) -> Data? {
        #if canImport(AppKit)
        let bitmapRep = NSBitmapImageRep(ciImage: self)
        let jpegData = bitmapRep.representation(using: .JPEG, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: NSNumber(value: quality)])

        return jpegData
        #else
        return UIImage(ciImage: self).jpegData(compressionQuality: quality)
        #endif
    }
}
