//
//  UIColor.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 24.03.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//
// swiftlint:disable force_unwrapping

import Foundation
import UIKit.UIColor

extension UIColor {

    static var paDelete: UIColor { return UIColor(named: "Delete")! }
    static var paDarkGray: UIColor { return UIColor(named: "DarkGray")! }
    static var paLightGray: UIColor { return UIColor(named: "LightGray")! }
    static var paWhite: UIColor { return UIColor(named: "White")! }
    static var paDarkRed: UIColor { return UIColor(named: "DarkRed")! }
    static var paLightRed: UIColor { return UIColor(named: "LightRed")! }

    static var paPDFBackground: UIColor { return UIColor(named: "PDFBackground")! }
    static var paBackground: UIColor { return UIColor(named: "Background")! }
    static var paSecondaryBackground: UIColor { return UIColor(named: "SecondaryBackground")! }
    static var paKeyboardBackground: UIColor { return UIColor(named: "KeyboardBackground")! }
    static var paPlaceholderGray: UIColor { return UIColor(named: "PlaceholderGray")! }
}
