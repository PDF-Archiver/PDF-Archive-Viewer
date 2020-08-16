//
//  FolderProvider.swift
//  
//
//  Created by Julian Kahnert on 16.08.20.
//

import Foundation

public protocol FolderProvider {
    typealias FileChangeHandler = (Self, [FileChange]) -> Void

//    var folderDidChange: FileChangeHandler? { get }

    init(_ handler: FileChangeHandler)

    func download(url: URL) throws
    func delete(url: URL) throws
//    func getFilename(of url: URL) -> String
//    func getFilesize(of url: URL) -> Int64
}

public enum FileChange {
    case added(Details)
    case updated(Details)
    case removed

    public struct Details {
        let url: URL
        let filename: String
        let size: Int
        let downloadStatus: DownloadStatus
    }
}
