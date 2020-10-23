//
//  ContentView.swift
//  AppClip
//
//  Created by Julian Kahnert on 10.10.20.
//

import ArchiveViews
import ArchiveBackend
import Combine
import SwiftUI
import StoreKit

struct MainContentView: View {
    static let imageConverter = ImageConverter(getDocumentDestination: { PathManager.tempPdfURL },
                                               shouldStartBackgroundTask: false)

    @StateObject private var scanViewModel = ScanTabViewModel(imageConverter: imageConverter,
                                                              iapService: AppClipIAPService(),
                                                              documentsFinishedHandler: documentsProcessingCompleted)
    @StateObject private var alertViewModel = AlertViewModel()

    private static func documentsProcessingCompleted() {
        // TODO: find document in folder first
        NotificationCenter.default.post(name: .foundProcessedDocument, object: nil)
    }
    
    var body: some View {
        ZStack {
            ScanTabView(viewModel: scanViewModel)
                .alert(isPresented: $alertViewModel.showAlert) {
                    Alert(viewModel: alertViewModel.alertViewModel)
                }

            PDFSharingView()

            if scanViewModel.showDocumentScan {
                documentCameraView
            } else {
                VStack {
                    Spacer()
                    Text("App Store Overlay")
                        .hidden()
                        .appStoreOverlay(isPresented: .constant(true)) {
                            SKOverlay.AppClipConfiguration(position: .bottom)
                        }
                }
            }
        }
        // TODO: remove this
        .onAppear {
            #if DEBUG
            NotificationCenter.default.post(name: .foundProcessedDocument, object: nil)
            #endif
        }
    }

    private var documentCameraView: some View {
        DocumentCameraView(isShown: $scanViewModel.showDocumentScan,
                           imageHandler: scanViewModel.process)
            .edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}
#endif
