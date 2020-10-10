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

public extension UIColor {

    public static var paDelete: UIColor { return UIColor(named: "Delete")! }
    public static var paDarkGray: UIColor { return UIColor(named: "DarkGray")! }
    public static var paLightGray: UIColor { return UIColor(named: "LightGray")! }
    public static var paWhite: UIColor { return UIColor(named: "White")! }
    public static var paDarkRed: UIColor { return UIColor(named: "DarkRed")! }
    public static var paLightRed: UIColor { return UIColor(named: "LightRed")! }

    public static var paPDFBackground: UIColor { return UIColor(named: "PDFBackground")! }
    public static var paBackground: UIColor { return UIColor(named: "Background")! }
    public static var paSecondaryBackground: UIColor { return UIColor(named: "SecondaryBackground")! }
    public static var paKeyboardBackground: UIColor { return UIColor(named: "KeyboardBackground")! }
    public static var paPlaceholderGray: UIColor { return UIColor(named: "PlaceholderGray")! }
}
