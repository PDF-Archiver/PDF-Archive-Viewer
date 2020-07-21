//
//  ArchiveStore.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 24.06.20.
//

import Combine
import Foundation

public final class ArchiveStore: ObservableObject, Log {

    public enum State {
        case uninitialized, cachedDocuments, live
    }

    private static let savePath: URL = {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { fatalError("No cache dir found.")}
        return url.appendingPathComponent("ArchiveData.json")
    }()
    public static let shared = ArchiveStore()

    @Published public var state: State = .uninitialized
    @Published public var documents: [Document] = []

    public var years: Set<String> {
        var years = Set<String>()
        for document in documents {
            guard document.folder.isNumeric,
                  document.folder.count <= 4 else { continue }
            years.insert(document.folder)
        }
        return years
    }

    private var archiveFolder: URL!

    private let queue = DispatchQueue(label: UUID().uuidString)
    private let fileProperties: [URLResourceKey] = [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .fileSizeKey, .localizedNameKey]
    private var contents = [URL: [URL]]()
    private var watchers = [DirectoryDeepWatcher]()

    private var allFiles: [URL] {
        contents.reduce(into: [URL]()) { (result, item) in
            result.append(contentsOf: item.value)
        }
    }

    private init() {
        DispatchQueue.global().async {
            self.loadDocuments()
        }
    }

    // MARK: Public API

    public func update(archiveFolder: URL, observedFolders: [URL]) {
        var observedFolders = observedFolders
        self.archiveFolder = archiveFolder

        contents = [:]
        observedFolders.append(archiveFolder)
        for folder in observedFolders {

            guard let watcher = DirectoryDeepWatcher.watch(folder) else { continue }
            watchers.append(watcher)
            watcher.onFolderNotification = { [weak self] folder in
                self?.folderDidChange(folder, shouldUpdateDocuments: true)
            }

            folderDidChange(folder, shouldUpdateDocuments: false)
        }

        updateDocuments()
    }

    // MARK: Load & Save

    private func loadDocuments() {
        do {
            let data = try Data(contentsOf: Self.savePath)
            documents = try JSONDecoder().decode([Document].self, from: data)
            state = .cachedDocuments
            log.info("Documents loaded.")
        } catch {
            log.error("JSON decoding error", metadata: ["error": "\(error.localizedDescription)"])

            try? FileManager.default.removeItem(at: Self.savePath)
        }
    }

    private func saveDocuments() {
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: Self.savePath)
            log.info("Documents saved.")
        } catch {
            log.error("JSON encoding error", metadata: ["error": "\(error.localizedDescription)"])
        }
    }

    // MARK: Helper Function

    private func folderDidChange(_ url: URL, shouldUpdateDocuments: Bool = true) {
        contents[url] = []

        let startingPoint = Date()
        contents[url] = url.getFilesRecursive(fileProperties: fileProperties)
        print("\(startingPoint.timeIntervalSinceNow * -1) seconds elapsed")

        guard shouldUpdateDocuments else { return }
        updateDocuments()
    }

    private func updateDocuments() {
        var documents = [Document]()
        for file in allFiles {
            let values = try? file.resourceValues(forKeys: Set(fileProperties))

            let downloadState: Document.DownloadStatus
            if values?.ubiquitousItemIsDownloading ?? false {
                downloadState = .downloading
            } else if values?.ubiquitousItemDownloadingStatus == URLUbiquitousItemDownloadingStatus.notDownloaded {
                downloadState = .iCloudDrive
            } else {
                downloadState = .local
            }

            documents.append(Document(path: file, size: values?.totalFileAllocatedSize, downloadStatus: downloadState))
        }
        self.documents = documents
        log.info("Found \(documents.count) documents.")
        self.state = .live
        DispatchQueue.global(qos: .background).async {
            self.saveDocuments()
        }
    }

    func getTaggingStatus(of url: URL) -> Document.TaggingStatus {

        // Could document be found in the untagged folder?
//        guard url.path.hasPrefix(archiveFolder.path) else { return .untagged }

        // Do "--" and "__" exist in filename?
        guard url.lastPathComponent.contains("--"),
            url.lastPathComponent.contains("__"),
            !url.lastPathComponent.contains(Constants.documentDatePlaceholder),
            !url.lastPathComponent.contains(Constants.documentDescriptionPlaceholder),
            !url.lastPathComponent.contains(Constants.documentTagPlaceholder) else { return .untagged }

        return .tagged
    }
}
