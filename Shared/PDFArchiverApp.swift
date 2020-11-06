//
//  PDFArchiverApp.swift
//  Shared
//
//  Created by Julian Kahnert on 24.06.20.
//

@_exported import ArchiveBackend
@_exported import ArchiveViews

import Diagnostics
import Foundation
import Logging
import Sentry
import SwiftUI

@main
struct PDFArchiverApp: App, Log {

    @Environment(\.scenePhase) private var scenePhase

    init() {
        setup()
    }

    var body: some Scene {
        WindowGroup {
            MainNavigationView()
                .environmentObject(OrientationInfo())
                .onChange(of: scenePhase) { phase in
                    Self.log.info("Scene change: \(phase)")

                    // schedule a new background task
                    if phase != .active,
                       MainNavigationViewModel.imageConverter.totalDocumentCount.value > 0 {
                        BackgroundTaskScheduler.shared.scheduleTask(with: .pdfProcessing)
                    }
                }
        }
//        #if os(macOS)
//        Settings {
//            Text("Test")
//        }
//        #endif
    }

    private func setup() {

        do {
            try DiagnosticsLogger.setup()
            UserDefaultsReporter.userDefaults = UserDefaults.appGroup
        } catch {
            log.warning("Failed to setup the Diagnostics Logger")
        }

        LoggingSystem.bootstrap { label in
            var sysLogger = StreamLogHandler.standardOutput(label: label)
            sysLogger.logLevel = AppEnvironment.get() == .production ? .info : .trace
            return sysLogger
        }

        DispatchQueue.global().async {

            UserDefaults.runMigration()

            // start document service
            _ = ArchiveStore.shared
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

        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (_, error) in
                if let error = error {
                    Self.log.errorAndAssert("Failed to get notification authorization", metadata: ["error": "\(error)"])
                }
            }
        }
        #endif
    }
}
