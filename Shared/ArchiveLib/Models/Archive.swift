//
//  Archive.swift
//  ArchiveLib
//
//  Created by Julian Kahnert on 09.12.18.
//

import Combine
import Foundation

//public protocol ArchiveDelegate: AnyObject {
//    func archive(_ archive: Archive, didAddDocument document: Document)
//    func archive(_ archive: Archive, didRemoveDocuments documents: Set<Document>)
//}
//
//public class Archive: DocumentManagerHandling {
//
//    private let taggedDocumentManager = DocumentManager()
//    private let untaggedDocumentManager = DocumentManager()
//
//    private let queue: OperationQueue = {
//        let workerQueue = OperationQueue()
//
//        // a higher QoS seems to result spinner showing at app launch
//        workerQueue.qualityOfService = .utility
//        workerQueue.name = (Bundle.main.bundleIdentifier ?? "PDFArchiver") + ".parseContent"
//        return workerQueue
//    }()
//
//    public weak var delegate: ArchiveDelegate?
//
//    public init() {
////        DispatchQueue.main.async {
////            let path = FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents")
////            ArchiveStore.shared.update(observedFolders: [path])
////
////            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(5)) {
////                try? "Test".write(to: path.appendingPathComponent(UUID().uuidString), atomically: true, encoding: .utf8)
////            }
////        }
//    }
//
//    // MARK: - TagManagerHandling implementation
//    public func getAvailableTags(with searchterms: [String]) -> Set<String> {
//
//        // search in filename of the documents
//        let documents = taggedDocumentManager.filter(by: searchterms).union(untaggedDocumentManager.filter(by: searchterms))
//
//        // get a set of all document tags
//        let allDocumentTags = documents.reduce(into: Set<String>()) { result, document in
//            result.formUnion(document.tags)
//        }
//
//        let filteredTags: Set<String>
//        if searchterms.isEmpty {
//            filteredTags = allDocumentTags
//        } else {
//            // filter the tags that match any searchterm
//            filteredTags = allDocumentTags.filter { tag in
//                searchterms.contains { tag.lowercased().contains($0.lowercased()) }
//            }
//        }
//
//        return filteredTags
//    }
//
//    // MARK: - DocumentHandling implementation
//    public var years: Set<String> {
//        var years = Set<String>()
//        for document in taggedDocumentManager.documents.value {
//            guard document.folder.isNumeric,
//                document.folder.count <= 4 else { continue }
//            years.insert(document.folder)
//        }
//        return years
//    }
//
//    public func get(scope: SearchScope, searchterms: [String], status: Document.TaggingStatus) -> Set<Document> {
//
//        let documentManager: DocumentManager
//        switch status {
//        case .tagged:
//            documentManager = taggedDocumentManager
//        case .untagged:
//            documentManager = untaggedDocumentManager
//        }
//
//        // filter by scope
//        let scopeFilteredDocuments: Set<Document>
//        switch scope {
//        case .all:
//            scopeFilteredDocuments = documentManager.allSearchElements
//        case .year(let year):
//            scopeFilteredDocuments = documentManager.allSearchElements.filter { $0.folder == year }
//        }
//
//        // filter by search terms
//        let termFilteredDocuments = documentManager.filter(by: searchterms)
//
//        return scopeFilteredDocuments.intersection(termFilteredDocuments)
//    }
//
//    // TODO: make this private
//    func add(from path: URL, size: Int?, downloadStatus: FileChange.DownloadStatus, status: Document.TaggingStatus, parse parsingOptions: ParsingOptions = []) {
//
//        // swiftlint:disable first_where
//        switch status {
//        case .untagged:
//            if let foundDocument = untaggedDocumentManager.filter(by: path.lastPathComponent).first {
//                update(foundDocument)
//                return
//            }
//        case .tagged:
//            if let foundDocument = taggedDocumentManager.filter(by: path.lastPathComponent).first {
//                update(foundDocument)
//                return
//            }
//        }
//        // swiftlint:enable first_where
//
//        let newDocument = Document(path: path, size: size, downloadStatus: downloadStatus, taggingStatus: status)
//        switch status {
//        case .tagged:
//            taggedDocumentManager.add(newDocument)
//        case .untagged:
//
//            if !parsingOptions.isEmpty {
//
//                // parse the document content, which might updates the date and tags
//                if parsingOptions.contains(.mainThread) {
//                    newDocument.parseContent(parsingOptions)
//                } else {
//                    if !isAlreadyParsing(document: newDocument) {
//                        // parse the document content, which might updates the date and tags
//                        queue.addOperation(ContentParseOperation(with: newDocument, options: parsingOptions))
//                    }
//                }
//            }
//
//            // add the document to the untagged documents
//            untaggedDocumentManager.add(newDocument)
//        }
//
//        delegate?.archive(self, didAddDocument: newDocument)
//    }
//
//    public func remove(_ removableDocuments: Set<Document>) {
//
//        let taggedDocuments = removableDocuments.filter { $0.taggingStatus == .tagged }
//        taggedDocumentManager.remove(taggedDocuments)
//        untaggedDocumentManager.remove(removableDocuments.subtracting(taggedDocuments))
//
//        delegate?.archive(self, didRemoveDocuments: removableDocuments)
//    }
//
////    public func removeAll(_ status: TaggingStatus) {
////
////        // get the right document manager
////        let documentManager: DocumentManager
////        switch status {
////        case .tagged:
////            documentManager = taggedDocumentManager
////        case .untagged:
////            documentManager = untaggedDocumentManager
////        }
////
////        // remove the documents
////        documentManager.removeAll()
////    }
//
//    public func update(_ document: Document) {
//        switch document.taggingStatus {
//        case .tagged:
//            taggedDocumentManager.update(document)
//        case .untagged:
//            untaggedDocumentManager.update(document)
//        }
//    }
//
//    public func archive(_ document: Document) {
//        untaggedDocumentManager.remove(document)
//        taggedDocumentManager.add(document)
//    }
//
//    public func update(from path: URL, size: Int?, downloadStatus: FileChange.DownloadStatus, status: Document.TaggingStatus, parse parsingOptions: ParsingOptions = []) -> Document {
//
////        let documentId: UUID
////        if let foundDocument = get(scope: .all, searchterms: [path.lastPathComponent], status: status).first {
////            documentId = foundDocument.id
////        } else {
////            documentId = UUID()
////        }
//
//        let updatedDocument = Document(path: path, size: size, downloadStatus: downloadStatus, taggingStatus: status)
//        update(updatedDocument)
//        return updatedDocument
//    }
//
//    private func update(_ document: Document, with parsingOptions: ParsingOptions) {
//        switch document.taggingStatus {
//        case .tagged:
//            taggedDocumentManager.update(document)
//        case .untagged:
//
//            if !parsingOptions.isEmpty && !isAlreadyParsing(document: document) {
//                // parse the document content, which might updates the date and tags
//                queue.addOperation(ContentParseOperation(with: document, options: parsingOptions))
//            }
//
//            // add the document to the untagged documents
//            untaggedDocumentManager.update(document)
//        }
//
//        delegate?.archive(self, didAddDocument: document)
//    }
//
//    // MARK: - Content parsing queue actions
//
////    public func cancelOperations(on document: Document) {
////        (queue.operations as? [ContentParseOperation] ?? [])
////            .filter { $0.document == document }
////            .forEach { $0.cancel() }
////    }
//
//    private func isAlreadyParsing(document: Document) -> Bool {
//        guard let operations = queue.operations as? [ContentParseOperation] else { fatalError("Could not get operations.") }
//        return operations.contains { $0.document == document }
//    }
//
//    // MARK: Tag Index
//
//    /// Get all tags that are used in other documents with the given `tagname`.
//    /// - Parameter tagname: Given tag name.
//    public func getSimilarTags(for tagname: String) -> Set<String> {
//        return taggedDocumentManager.tagIndex.value[tagname]
//    }
//}
//
//public enum ContentType: Equatable {
//    case tags
//    case untaggedDocuments
//    case archivedDocuments(updatedDocuments: Set<Document>)
//}
