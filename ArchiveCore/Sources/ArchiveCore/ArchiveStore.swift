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
    @Published public var years: Set<String> = []

    private var archiveFolder: URL!
    private var untaggedFolders: [URL] = []

    private let fileProperties: [URLResourceKey] = [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .fileSizeKey, .localizedNameKey]
    private var contents = [URL: [Document]]()
    private var watchers = [DirectoryDeepWatcher]()

    private init() {
        DispatchQueue.global().async {
            self.loadDocuments()
        }
    }

    // MARK: Public API

    public func update(archiveFolder: URL, untaggedFolders: [URL]) {
        var observedFolders = untaggedFolders
        self.archiveFolder = archiveFolder

        contents = [:]
        try? FileManager.default.removeItem(at: Self.savePath)

        observedFolders.append(archiveFolder)
        for folder in observedFolders {

            guard let watcher = DirectoryDeepWatcher.watch(folder) else { continue }
            watchers.append(watcher)
            watcher.onFolderNotification = { [weak self] folder in
                self?.folderDidChange(folder)
                self?.updateDocuments()
            }

            folderDidChange(folder)
        }

        updateDocuments()
    }

    // MARK: Load & Save

    private func loadDocuments() {
        do {
            let data = try Data(contentsOf: Self.savePath)
            documents = try JSONDecoder().decode([Document].self, from: data)
            state = .cachedDocuments
            log.info("\(documents.count) documents loaded.")
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

    private func folderDidChange(_ folderUrl: URL) {

        let oldDocuments = contents[folderUrl] ?? []
        let newUrls = folderUrl.getFilesRecursive(fileProperties: fileProperties)

        contents[folderUrl] = newUrls.map { url in

            let taggingStatus = getTaggingStatus(of: url)

            // get a document or create a new one
            let document: Document
            let parsingOptions: ParsingOptions
            if let foundDocument = oldDocuments.first(where: { $0.path == url }) {
                document = foundDocument
                parsingOptions = []
            } else {

                // TODO: get filesize from provider
                let size: Int64 = 123

                document = Document(path: url, taggingStatus: taggingStatus, downloadStatus: .downloading(percent: 0.1234), byteSize: size)

                // only parse untagged documents
                parsingOptions = taggingStatus == .untagged ? .all : []
            }

            // TODO: abstract this be moving it to a fileprovider
            // update the download status
            let values = try? url.resourceValues(forKeys: Set(fileProperties))
            let downloadStatus: FileChange.DownloadStatus
            if values?.ubiquitousItemIsDownloading ?? false {
                downloadStatus = .downloading(percent: 0.123)
            } else if values?.ubiquitousItemDownloadingStatus == URLUbiquitousItemDownloadingStatus.notDownloaded {
                downloadStatus = .remote
            } else {
                downloadStatus = .local
            }

            document.update(with: downloadStatus, contentParsingOptions: parsingOptions)

            return document
        }
    }

    private func updateDocuments() {

        self.documents = contents
            .flatMap { $0.value }
            .sorted()

        var years = Set<String>()
        for document in self.documents {
            let folder = document.path.deletingLastPathComponent().lastPathComponent
            guard folder.isNumeric,
                  folder.count <= 4 else { continue }
            years.insert(folder)
        }
        self.years = years

        log.info("Found \(documents.count) documents.")
        self.state = .live
        DispatchQueue.global(qos: .background).async {
            self.saveDocuments()
        }
    }

    func getTaggingStatus(of url: URL) -> Document.TaggingStatus {

        // Could document be found in the untagged folder?
        guard untaggedFolders.contains(where: { url.path.hasPrefix($0.path) }) else { return .tagged }

        // Do "--" and "__" exist in filename?
        guard url.lastPathComponent.contains("--"),
            url.lastPathComponent.contains("__"),
            !url.lastPathComponent.contains(Constants.documentDatePlaceholder),
            !url.lastPathComponent.contains(Constants.documentDescriptionPlaceholder),
            !url.lastPathComponent.contains(Constants.documentTagPlaceholder) else { return .untagged }

        return .tagged
    }
}
