//
//  FolderProvider.swift
//  
//
//  Created by Julian Kahnert on 16.08.20.
//

import Foundation
import LoggingKit

// TODO: add WebDAV support. An example Swift Package with several FileProvider Implementations is: https://github.com/amosavian/FileProvider
// example implementations: https://github.com/amosavian/FileProvider/blob/master/Sources/FileProvider.swift
public protocol FolderProvider: class, Log {
    typealias FolderChangeHandler = (FolderProvider, [FileChange]) -> Void

    static func canHandle(_ url: URL) -> Bool

    var baseUrl: URL { get }
//    var type: FolderType { get }
//    var folderDidChange: FolderChangeHandler? { get }

    init(baseUrl: URL, _ handler: @escaping FolderChangeHandler)

    func save(data: Data, at: URL) throws
    func startDownload(of: URL) throws
    func fetch(url: URL) throws -> Data
    func delete(url: URL) throws
    func rename(from: URL, to: URL) throws
}

enum FolderProviderError: Error {
    case notSupported
}

public enum FolderType: Equatable {
    case iCloudDrive, local
}
