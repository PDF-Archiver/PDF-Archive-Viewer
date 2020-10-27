//
//  UserDefaults.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 10.08.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Foundation

extension UserDefaults: Log {

    public enum Names: String, CaseIterable {
        case tutorialShown = "tutorial-v1"
        case lastSelectedTabName
        case pdfQuality
        case subscriptionExpiryDate = "SubscriptionExpiryDate"
        case firstDocumentScanAlertPresented
        case archiveURL
        case untaggedURL
    }

    public enum PDFQuality: Float, CaseIterable {
        case lossless = 1.0
        case good = 0.75
        case normal = 0.5
        case small = 0.25

        public static let defaultQualityIndex = 1  // e.g. "good"

        public static func toIndex(_ quality: PDFQuality) -> Int {
            let allCases = UserDefaults.PDFQuality.allCases
            return allCases.firstIndex(of: quality) ?? defaultQualityIndex
        }
    }

    public var tutorialShown: Bool {
        get {
            bool(forKey: Names.tutorialShown.rawValue)
        }
        set {
            set(newValue, forKey: Names.tutorialShown.rawValue)
        }
    }

    public var firstDocumentScanAlertPresented: Bool {
        get {
            bool(forKey: Names.firstDocumentScanAlertPresented.rawValue)
        }
        set {
            set(newValue, forKey: Names.firstDocumentScanAlertPresented.rawValue)
        }
    }

    public var lastSelectedTab: Tab {
        get {
            guard let name = string(forKey: Names.lastSelectedTabName.rawValue),
                let tab = Tab(rawValue: name) else { return .scan }
            return tab
        }
        set {
            set(newValue.rawValue, forKey: Names.lastSelectedTabName.rawValue)
        }
    }

    public var pdfQuality: PDFQuality {
        get {
            var value = float(forKey: Names.pdfQuality.rawValue)

            // set default to 0.75
            if value == 0.0 {
                value = PDFQuality.allCases[PDFQuality.defaultQualityIndex].rawValue
            }

            guard let level = PDFQuality(rawValue: value) else { fatalError("Could not parse level from value \(value).") }
            return level
        }
        set {
            log.info("PDF Quality Changed.", metadata: ["quality": "\(newValue.rawValue)"])
            set(newValue.rawValue, forKey: Names.pdfQuality.rawValue)
        }
    }

    public var subscriptionExpiryDate: Date? {
        get {
            object(forKey: Names.subscriptionExpiryDate.rawValue) as? Date
        }
        set {
            set(newValue, forKey: Names.subscriptionExpiryDate.rawValue)
        }
    }

    public var archiveURL: URL? {
        get {
            object(forKey: Names.archiveURL.rawValue) as? URL
        }
        set {
            set(newValue, forKey: Names.archiveURL.rawValue)
        }
    }

    public var untaggedURL: URL? {
        get {
            object(forKey: Names.untaggedURL.rawValue) as? URL
        }
        set {
            set(newValue, forKey: Names.untaggedURL.rawValue)
        }
    }

    // MARK: - Migration

    public static var appGroup: UserDefaults {
        UserDefaults(suiteName: Constants.sharedContainerIdentifier)!
    }

    public static func runMigration() {
        let old = UserDefaults.standard
        let new = UserDefaults.appGroup

        for name in Names.allCases {
            if let value = old.object(forKey: name.rawValue) {
                // if an old value could be found, set it in the new UserDefaults
                new.set(value, forKey: name.rawValue)

                // remove the old value after the migration has been completed, so that this will only run one time
                old.set(nil, forKey: name.rawValue)
            }
        }
    }
}
