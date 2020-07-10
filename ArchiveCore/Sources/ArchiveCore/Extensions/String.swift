//
//  File.swift
//  
//
//  Created by Julian Kahnert on 25.10.19.
//

import Foundation

extension String {
    public var isNumeric: Bool {
        CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }

    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
