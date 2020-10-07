//
//  UserDefaults.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 10.08.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Foundation
import LoggingKit

extension UserDefaults: Log {

    private enum Names: String {
        case tutorialShown = "tutorial-v1"
        case lastSelectedTabName
        case pdfQuality
        case subscriptionExpiryDate = "SubscriptionExpiryDate"
        case firstDocumentScanAlertPresented
    }

    enum PDFQuality: Float, CaseIterable {
        case lossless = 1.0
        case good = 0.75
        case normal = 0.5
        case small = 0.25

        static let defaultQualityIndex = 1  // e.g. "good"

        static func toIndex(_ quality: PDFQuality) -> Int {
            let allCases = UserDefaults.PDFQuality.allCases
            return allCases.firstIndex(of: quality) ?? defaultQualityIndex
        }
    }

    var tutorialShown: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Names.tutorialShown.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Names.tutorialShown.rawValue)
        }
    }

    var firstDocumentScanAlertPresented: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Names.firstDocumentScanAlertPresented.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Names.firstDocumentScanAlertPresented.rawValue)
        }
    }

    var lastSelectedTab: Tab {
        get {
            guard let name = UserDefaults.standard.string(forKey: Names.lastSelectedTabName.rawValue),
                let tab = Tab(rawValue: name) else { return .scan }
            return tab
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Names.lastSelectedTabName.rawValue)
        }
    }

    var pdfQuality: PDFQuality {
        get {
            var value = UserDefaults.standard.float(forKey: Names.pdfQuality.rawValue)

            // set default to 0.75
            if value == 0.0 {
                value = PDFQuality.allCases[PDFQuality.defaultQualityIndex].rawValue
            }

            guard let level = PDFQuality(rawValue: value) else { fatalError("Could not parse level from value \(value).") }
            return level
        }
        set {
            log.info("PDF Quality Changed.", metadata: ["quality": "\(newValue.rawValue)"])
            UserDefaults.standard.set(newValue.rawValue, forKey: Names.pdfQuality.rawValue)
        }
    }

    var subscriptionExpiryDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: Names.subscriptionExpiryDate.rawValue) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Names.subscriptionExpiryDate.rawValue)

        }
    }
}
