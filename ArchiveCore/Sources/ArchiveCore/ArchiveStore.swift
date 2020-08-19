//
//  ArchiveStore.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 24.06.20.
//

import Combine
import Foundation
import LoggingKit

public final class ArchiveStore: ObservableObject, Log {

    public enum State {
        case uninitialized, cachedDocuments, live
    }

    private static let availableProvider: [FolderProvider.Type] = [
        ICloudFolderProvider.self,
        LocalFolderProvider.self
    ]

    private static let fileProperties: [URLResourceKey] = [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .fileSizeKey, .localizedNameKey]
    private static let savePath: URL = {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { fatalError("No cache dir found.")}
        return url.appendingPathComponent("ArchiveData.json")
    }()
    public static let shared = ArchiveStore()

    @Published public var state: State = .uninitialized
    @Published public var documents: [Document] = []
    @Published public var years: Set<String> = []

    private var untaggedFolders: [URL] = []

    private let queue = DispatchQueue(label: "ArchiveStoreQueue", qos: .utility)
    private var providers: [FolderProvider] = []
    private var contents: [URL: [Document]] = [:]

    private init() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadDocuments()
        }
    }

    // MARK: Public API

    public func update(archiveFolder: URL, untaggedFolders: [URL]) {
        self.untaggedFolders = untaggedFolders
        let observedFolders = [[archiveFolder], untaggedFolders].flatMap { $0 }

        queue.sync {
            contents = [:]
        }
        try? FileManager.default.removeItem(at: Self.savePath)

        providers = observedFolders.map { folder in
            guard let provider = Self.availableProvider.first(where: { $0.canHandle(folder) }) else {
                preconditionFailure("Could not find a FolderProvider for: \(folder.path)")
            }
            return provider.init(baseUrl: folder, folderDidChange(_:_:))
        }
    }

    // MARK: Helper Function

    private func folderDidChange(_ provider: FolderProvider, _ changes: [FileChange]) {
        queue.sync {
            for change in changes {

                var document: Document?
                var contentParsingOptions: ParsingOptions?

                switch change {
                    case .added(let details):
                        let taggingStatus = getTaggingStatus(of: details.url)
                        document = Document(from: details, with: taggingStatus)

                        // parse document content only for untagged documents
                        contentParsingOptions = taggingStatus == .untagged ? .all : []

                    case .removed(let url):
                        contents[provider.baseUrl]?.removeAll { $0.path == url }

                    case .updated(let details):
                        if let foundDocument = contents[provider.baseUrl]?.first(where: { $0.path == details.url }) {
                            document = foundDocument
                        } else {
                            let taggingStatus = getTaggingStatus(of: details.url)
                            document = Document(from: details, with: taggingStatus)
                        }

                        contents[provider.baseUrl]?.removeAll { $0.path == details.url }

                        contentParsingOptions = []
                }

                if let document = document {
                    contents[provider.baseUrl, default: []].append(document)
                    contents[provider.baseUrl]?.sort()

                    // trigger update of the document properties
                    if let contentParsingOptions = contentParsingOptions {
                        DispatchQueue.global(qos: .userInitiated).async {
                            // TODO: add this as an WorkItem to an queue and save documents after the last has been written
                            document.updateProperties(with: document.downloadStatus, contentParsingOptions: contentParsingOptions)
                        }
                    }
                }
            }
        }

        updateDocuments()
    }

    private func updateDocuments() {
        var documents = [Document]()
        queue.sync {
            documents = self.contents
                .flatMap { $0.value }
                .sorted()
        }
        self.documents = documents

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
}
