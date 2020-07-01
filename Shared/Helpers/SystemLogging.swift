//
//  Logging.swift
//  ArchiveLib
//
//  Created by Julian Kahnert on 13.11.18.
//

import Foundation
import os.log

/// Logging protocel
public protocol SystemLogging {

    /// Property that should be used for generating logs.
    static var log: OSLog { get }
}

extension SystemLogging {

    /// Getting an OSLog instance for logging.
    public static var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier ?? "ArchiveLib",
                     category: String(describing: type(of: self)))
    }
}
