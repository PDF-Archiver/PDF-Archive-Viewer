//
//  ArchiveStore.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 24.06.20.
//

import Combine
import Foundation

class ArchiveStore: ObservableObject {

    static let shared = ArchiveStore()

    @Published var taggedDocuments: [Document] = []
    @Published var untaggedDocuments: [Document] = []

    private var folderMonitors = [FolderMonitor]()
    private var contents = [URL: [Document]]()

    private init() {}

    func update(observedFolders: [URL]) {
        contents = [:]
        for folder in observedFolders {
            folderMonitors.append(FolderMonitor(url: folder, folderDidChange: folderDidChange))
            folderDidChange(folder)
        }
    }

    private func folderDidChange(_ url: URL) {

//        do {
//        let fileProperties: [URLResourceKey] = [.ubiquitousItemDownloadingStatusKey]
//        let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: fileProperties, options: [])
//        try files[0].resourceValues(forKeys: Set(fileProperties)).ubiquitousItemDownloadingStatus
//        
//        files[0].resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]).ubiquitousItemDownloadingStatus == URLUbiquitousItemDownloadingStatus.notDownloaded
//        } catch {
//            // TODO: send notification with error
//        }

    }
}
