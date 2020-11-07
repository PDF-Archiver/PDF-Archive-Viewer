//
//  CustomDiagnosticsReporter.swift
//  
//
//  Created by Julian Kahnert on 07.11.20.
//

import Diagnostics
import Foundation

public struct CustomDiagnosticsReporter: DiagnosticsReporting {
    public static func report() -> DiagnosticsChapter {
        let documents = ArchiveStore.shared.documents
        let taggedCount = documents
            .filter { $0.taggingStatus == .tagged }
            .count
        let untaggedCount = documents.count - taggedCount

        let diagnostics: [String: String] = [
            "Environment": AppEnvironment.get().rawValue,
            "Version": AppEnvironment.getFullVersion(),
            "Number of tagged Documents": String(taggedCount),
            "Number of untagged Documents": String(untaggedCount),
            "Subscription Expiry Date": UserDefaults.appGroup.subscriptionExpiryDate?.description ?? "NULL"
        ]
        return DiagnosticsChapter(title: "App Environment", diagnostics: diagnostics)
    }
}
