//
//  UIImage.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 29.06.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

#if canImport(UIKit)
import UIKit.UIImage

extension UIImage {
    func crop(rectangle: CGRect) -> UIImage? {
        if let drawImage = self.cgImage?.cropping(to: rectangle) {
            return UIImage(cgImage: drawImage)
        }
        return nil
    }
}
#endif
