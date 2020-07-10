//
//  Constants.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 14.05.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//
// swiftlint:disable force_try

import Foundation

public enum Constants {
    public static let sharedContainerIdentifier = "group.PDFArchiverShared"

    public static let documentDatePlaceholder = "PDFARCHIVER-TEMP-DATE"
    public static let documentDescriptionPlaceholder = "PDF-ARCHIVER-TEMP-DESCRIPTION-"
    public static let documentTagPlaceholder = "PDFARCHIVERTEMPTAG"

    public static var sentryDsn: String {
        return "https://" + (try! Configuration.value(for: "SENTRY_DSN"))
    }

    public static var appStoreConnectSharedSecret: String {
        return try! Configuration.value(for: "APPSTORECONNECT_SHARED_SECRET")
    }

    public static var logUser: String {
        return try! Configuration.value(for: "LOG_USER")
    }

    public static var logPassword: String {
        return try! Configuration.value(for: "LOG_PASSWORD")
    }
}
