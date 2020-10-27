//
//  PathManager.swift
//  
//
//  Created by Julian Kahnert on 18.10.20.
//

import Foundation

public final class PathManager: Log {

    public static let shared = PathManager()

    public static var iCloudDriveURL: URL? {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        if url == nil {
            AlertDataModel.createAndPostNoICloudDrive()
        }
        return url
    }
    private static let appGroupContainerURL: URL = {
        guard let tempImageURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.sharedContainerIdentifier) else {
            log.assertOrCritical("AppGroup folder could not be found.")
            preconditionFailure("AppGroup folder could not be found.")
        }
        return tempImageURL
    }()

    public static let tempImageURL: URL = {
        let tempImageURL = appGroupContainerURL.appendingPathComponent("TempImages")
        do {
            try FileManager.default.createFolderIfNotExists(tempImageURL)
        } catch {
            log.assertOrCritical("Failed to create temp folder.", metadata: ["error": "\(error.localizedDescription)"])
            preconditionFailure("Failed to create temp folder.")
        }
        return tempImageURL
    }()

    public static let tempPdfURL: URL = {
        let tempImageURL = appGroupContainerURL.appendingPathComponent("TempPDFDocuments")
        do {
            try FileManager.default.createFolderIfNotExists(tempImageURL)
        } catch {
            log.assertOrCritical("Failed to create temp folder.", metadata: ["error": "\(error.localizedDescription)"])
            preconditionFailure("Failed to create temp folder.")
        }
        return tempImageURL
    }()

    public static var extensionTempPdfURL: URL {
        appGroupContainerURL
    }

    public static var appClipTempPdfURL: URL {
        tempPdfURL
    }

    public private(set) var archiveURL: URL?
    public private(set) var untaggedURL: URL?

    private init() {
        self.archiveURL = UserDefaults.appGroup.archiveURL ?? Self.iCloudDriveURL
        self.untaggedURL = UserDefaults.appGroup.untaggedURL ?? Self.iCloudDriveURL?.appendingPathComponent("untagged")
    }
}
