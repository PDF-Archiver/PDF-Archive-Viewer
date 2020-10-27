//
//  MainContentViewModel.swift
//  AppClip
//
//  Created by Julian Kahnert on 24.10.20.
//

import ArchiveViews
import Combine
import SwiftUI

final class MainContentViewModel: ObservableObject {
    static let imageConverter = ImageConverter(getDocumentDestination: { PathManager.tempPdfURL },
                                               shouldStartBackgroundTask: false)

    @Published var showAppStoreOverlay = false

    var sharingViewModel = PDFSharingViewModel()
    var scanViewModel = ScanTabViewModel(imageConverter: imageConverter,
                                         iapService: AppClipIAPService(),
                                         documentsFinishedHandler: documentsProcessingCompleted)
    var alertViewModel = AlertViewModel()
    private var disposables = Set<AnyCancellable>()

    init() {

        sharingViewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // bubble up the change from the nested view model
                self?.objectWillChange.send()

                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    self?.showAppStoreOverlay = self?.sharingViewModel.pdfDocument != nil
                }
            }
            .store(in: &disposables)

        scanViewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // bubble up the change from the nested view model
                self?.objectWillChange.send()
            }
            .store(in: &disposables)

        alertViewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // bubble up the change from the nested view model
                self?.objectWillChange.send()
            }
            .store(in: &disposables)
    }

    private static func documentsProcessingCompleted() {
        NotificationCenter.default.post(name: .foundProcessedDocument, object: nil)
    }
}
