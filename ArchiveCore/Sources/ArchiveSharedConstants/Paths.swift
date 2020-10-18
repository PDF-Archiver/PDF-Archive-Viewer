//
//  StorageHelper+Paths.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 11.05.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Foundation
import LoggingKit

public enum Paths: Log {

    public static let untaggedFolderName = "untagged"
    public static let tempFolderName = "temp"

    public static var archivePath: URL? = {
        guard let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            Self.log.assertOrError("Could not find default container identifier.")
            return nil
        }
        return containerUrl.appendingPathComponent("Documents")
    }()

    public static var untaggedPath: URL? = {
        guard let archivePath = archivePath else { return nil }
        return archivePath.appendingPathComponent(untaggedFolderName)
    }()

    public static var tempImagePath: URL? = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent(tempFolderName)
    }()
}
