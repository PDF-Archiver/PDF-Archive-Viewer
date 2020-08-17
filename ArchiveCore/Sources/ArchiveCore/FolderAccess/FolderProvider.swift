//
//  FolderProvider.swift
//  
//
//  Created by Julian Kahnert on 16.08.20.
//

import Foundation

// TODO: example implementations: https://github.com/amosavian/FileProvider/blob/master/Sources/FileProvider.swift
public protocol FolderProvider: class, Log {
    typealias FolderChangeHandler = (FolderProvider, [FileChange]) -> Void

    var type: FolderType { get }
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
