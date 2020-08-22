//
//  ArchiveViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 27.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//
// swiftlint:disable function_body_length

import ArchiveCore
import Combine
import Foundation
import LoggingKit
import UIKit

class ArchiveViewModel: ObservableObject, Log {

    static func createDetail(with document: Document) -> DocumentDetailView {
        let viewModel = DocumentDetailViewModel(document)
        return DocumentDetailView(viewModel: viewModel)
    }

    @Published private(set) var documents: [Document] = []
    @Published var years: [String] = ["All", "2019", "2018", "2017"]
    @Published var scopeSelecton: Int = 0
    @Published var searchText = ""
    @Published var showLoadingView = true

    private var disposables = Set<AnyCancellable>()
    private let archiveStore: ArchiveStore
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    init(_ archiveStore: ArchiveStore = ArchiveStore.shared) {
        self.archiveStore = archiveStore

        // MARK: - Combine Stuff
        archiveStore.$state
            .map { state -> Bool in
                state == .uninitialized
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.showLoadingView, on: self)
            .store(in: &disposables)

        archiveStore.$years
            .map { years -> [String] in
                ["All"] + Array(years.sorted().reversed().prefix(3))
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { years in
                self.years = years
            }
            .store(in: &disposables)

        // we assume that all documents should be loaded after 10 seconds
        // force the disappear of the loading view
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
            self.showLoadingView = false
        }

        $scopeSelecton
            .dropFirst()
            .sink { _ in
                self.selectionFeedback.prepare()
                self.selectionFeedback.selectionChanged()
            }
            .store(in: &disposables)

        // filter documents, get input from Notification, searchText or searchScope
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global(qos: .userInitiated))
            .removeDuplicates()
            .combineLatest($scopeSelecton, archiveStore.$documents)
            .map { (searchterm, searchscopeSelection, documents) -> [Document] in

                var searchterms: [String] = []
                if searchterm.isEmpty {
                    searchterms = []
                } else {
                    searchterms = searchterm
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: .whitespacesAndNewlines)
                }

                let searchscope = self.years[searchscopeSelection]
                if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: searchscope)) {
                    // found a year - it should be used as a searchterm
                    searchterms.append(searchscope)
                }

                return documents
                    .filter { $0.taggingStatus == .tagged }
                    .filter(by: searchterms)
                    .sorted()
                    .reversed()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] documents in
                guard let self = self else { return }

                self.documents = documents
            }
            .store(in: &disposables)
    }

    func tapped(_ document: Document) {
        log.debug("Tapped document: \(document.filename)")
        switch document.downloadStatus {
        case .remote:

            // trigger download of the selected document
            do {
                try archiveStore.download(document)
            } catch {
                AlertViewModel.createAndPost(message: error, primaryButtonTitle: "ok")
            }

//            var filteredDocuments = archiveStore.documents.filter { $0.id != document.id }
//            filteredDocuments.append(document)
//            archiveStore.documents = filteredDocuments

            // update the UI directly, by setting/updating the download status of this document
            // and triggering a notification
//            FileChange.DownloadStatus = .downloading
//            archive.update(document)
//            NotificationCenter.default.post(Notification(name: .documentChanges))

            notificationFeedback.notificationOccurred(.success)

        case .local:
            log.assertOrError("Already local - this should")
        case .downloading:
            log.debug("Already downloading")
        }
    }

    func delete(at offsets: IndexSet) {
        notificationFeedback.prepare()
        for index in offsets {
            let deletedDocument = documents.remove(at: index)
            do {
                try archiveStore.delete(deletedDocument)
            } catch {
                AlertViewModel.createAndPost(message: error, primaryButtonTitle: "ok")
            }
        }
        notificationFeedback.notificationOccurred(.success)
    }
}
