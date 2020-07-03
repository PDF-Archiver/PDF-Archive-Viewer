//
//  PDFArchiverApp.swift
//  Shared
//
//  Created by Julian Kahnert on 24.06.20.
//

import Diagnostics
import Foundation
import LogModel
import Sentry
import SwiftUI

@main
struct PDFArchiverApp: App {

    private static let sharedContainerIdentifier = "group.PDFArchiverShared"

    @Environment(\.scenePhase) private var scenePhase

    private var isInitialized = Atomic(false)
    private var isCurrentlyProcessing = Atomic(false)

//    @SceneBuilder
    var body: some Scene {
        WindowGroup {
            ContentView(app: self)
        }
//        #if os(macOS)
//        Settings {
//            Text("Test")
//        }
//        #endif
    }

    func sceneDidEnterForeground() {

        DispatchQueue.global().async {

            // TODO: how do we do this with SwiftUI only
            // start logging service by sending old events (if needed)
            //Log.sendOrPersistInBackground(application)

            // start IAP service
            _ = IAP.service

            // start document service
            _ = DocumentService.archive
            _ = DocumentService.documentsQuery
        }

        DispatchQueue.global(qos: .background).async {

        }

        guard !isInitialized.value else { return }

        do {
            try DiagnosticsLogger.setup()
        } catch {
            Log.send(.warning, "Failed to setup the Diagnostics Logger")
        }

        // Create a Sentry client and start crash handler
        SentrySDK.start(options: [
            "dsn": Constants.sentryDsn,
            "environment": AppEnvironment.get().rawValue,
            "release": AppEnvironment.getFullVersion(),
            "debug": false,
            "enableAutoSessionTracking": true
        ])

        SentrySDK.currentHub().getClient()?.options.beforeSend = { event in
            // I am not interested in this kind of data
            event.context?["device"]?["storage_size"] = nil
            event.context?["device"]?["free_memory"] = nil
            event.context?["device"]?["memory_size"] = nil
            event.context?["device"]?["boot_time"] = nil
            event.context?["device"]?["timezone"] = nil
            event.context?["device"]?["usable_memory"] = nil
            return event
        }
    }

    func sceneDidEnterBackground() {
        // send logs in background
        let application = UIApplication.shared
        Log.sendOrPersistInBackground(application)
    }

    // MARK: - Helper Functions

    private func initialize() {
        guard !self.isCurrentlyProcessing.value else { return }
        self.isCurrentlyProcessing.mutate { $0 = true }

        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.sharedContainerIdentifier) else {
            Log.send(.critical, "Failed to get url for forSecurityApplicationGroupIdentifier.")
            return
        }
        let urls = ((try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])) ?? [])
            .filter { !$0.hasDirectoryPath }

        if !urls.isEmpty {
            DispatchQueue.main.async {

                // TODO: add this

                // show scan tab with document processing, after importing a document
//                self.viewModel.currentTab = .scan
            }
        }

        for url in urls {
            self.handle(url: url)
        }
        self.isCurrentlyProcessing.mutate { $0 = false }
    }

    private func handle(url: URL) {
        Log.send(.info, "Handling shared document", extra: ["filetype": url.pathExtension])

        do {
            _ = url.startAccessingSecurityScopedResource()
            try StorageHelper.handle(url)
            url.stopAccessingSecurityScopedResource()
        } catch let error {
            url.stopAccessingSecurityScopedResource()
            Log.send(.error, "Unable to handle file.", extra: ["filetype": url.pathExtension, "error": error.localizedDescription])
            try? FileManager.default.removeItem(at: url)

            AlertViewModel.createAndPost(message: error, primaryButtonTitle: "OK")
        }
    }
}

extension PDFArchiverApp {
    // Workaround from: https://developer.apple.com/forums/thread/650632
    struct ContentView: View {
        @Environment(\.scenePhase) var scenePhase
        var app: PDFArchiverApp
        var body: some View {
            MainTabView()
                .accentColor(Color(.paDarkGray))
                .environmentObject(OrientationInfo())
                .onChange(of: scenePhase) { phase in
                    switch phase {
                    case .active, .inactive:
                        app.sceneDidEnterForeground()
                    case .background:
                        print("is background")
                        app.sceneDidEnterBackground()
                    @unknown default:
                        fatalError("This case is not handled.")
                    }
                }
        }
    }
}
