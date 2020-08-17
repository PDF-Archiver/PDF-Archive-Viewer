//
//  LocalFileProvider.swift
//  
//
//  Created by Julian Kahnert on 17.08.20.
//

import DeepDiff
import Foundation

class LocalFileProvider: FolderProvider {

    var type: FolderType = .local
    private let baseUrl: URL
    private let folderDidChange: FolderChangeHandler
    
    private let watcher: DirectoryDeepWatcher
    private let fileManager = FileManager.default
    private let fileProperties: [URLResourceKey] = [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .fileSizeKey, .localizedNameKey]
    
    private var currentFiles: [FileChange.Details] = []

    required init(baseUrl: URL, _ handler: @escaping (FolderProvider, [FileChange]) -> Void) {
        self.baseUrl = baseUrl
        self.folderDidChange = handler

        // TODO: start watching
        guard let watcher = DirectoryDeepWatcher.watch(baseUrl) else {
            preconditionFailure("Could not create local watcher.")
        }
        self.watcher = watcher
        watcher.onFolderNotification = { [weak self] folder in
            guard let self = self else { return }
//            self.folderDidChange(self, )
        }
        
        
    }
    
    // MARK: - API

    func save(data: Data, at url: URL) throws {
        try data.write(to: url)
    }

    func startDownload(of url: URL) throws {
        assertionFailure("Download of a local file is not supported")
        throw FolderProviderError.notSupported
    }

    func fetch(url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func delete(url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func rename(from source: URL, to destination: URL) throws {
        try fileManager.moveItem(at: source, to: destination)
    }
    
    // MARK: - Helper Functions
    
    private func createChanges() -> [FileChange] {
        let oldFiles = currentFiles
        let newFiles = baseUrl.getFilesRecursive(fileProperties: fileProperties)
            .compactMap { url -> FileChange.Details? in
                
                guard let resourceValues = try? url.resourceValues(forKeys: Set(fileProperties)),
                      let fileSize = resourceValues.fileSize else {
                    log.assertOrError("Could not fetch resource values from url.", metadata: ["url": "\(url.path)"])
                    return nil
                }
                
                let downloadStatus = getDownloadStatus(from: resourceValues)
                let filename: String
                if downloadStatus == .local {
                    filename = url.deletingPathExtension().lastPathComponent
                } else if let localizedName = resourceValues.localizedName {
                    filename = localizedName
                } else {
                    log.assertOrError("Filename could not be fetched.", metadata: ["url": "\(url.path)"])
                    return nil
                }

                return FileChange.Details(url: url, filename: filename, size: fileSize, downloadStatus: downloadStatus)
            }
            .sorted { $0.url.path < $1.url.path }
        
        currentFiles = newFiles
        
        return diff(old: oldFiles, new: newFiles)
            .flatMap { change -> [FileChange] in
                switch change {
                    case .insert(let insertDetails):
                        return [.added(insertDetails.item)]
                    case .delete(let deleteDetails):
                        return [.removed(deleteDetails.item.url)]
                    case .replace(let replaceDetails):
                        return [.removed(replaceDetails.oldItem.url), .added(replaceDetails.newItem)]
                    case .move(_):
                        // we are not interested in the
                        return []
                }
            }
    }
    
    private func getDownloadStatus(from values: URLResourceValues) -> FileChange.DownloadStatus {
        let downloadStatus: FileChange.DownloadStatus
        if values.ubiquitousItemIsDownloading ?? false {
            downloadStatus = .downloading(percent: 0.123)
        } else if values.ubiquitousItemDownloadingStatus == URLUbiquitousItemDownloadingStatus.notDownloaded {
            downloadStatus = .remote
        } else {
            downloadStatus = .local
        }
        return downloadStatus
    }
}
