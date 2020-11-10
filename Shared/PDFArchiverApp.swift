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
#if !os(macOS)
// TODO: add sentry again
import Sentry
#endif
import SwiftUI

#if os(macOS)
fileprivate typealias CustomWindowStyle = HiddenTitleBarWindowStyle
#else
fileprivate typealias CustomWindowStyle = DefaultWindowStyle
#endif

@main
struct PDFArchiverApp: App, Log {

    @Environment(\.scenePhase) private var scenePhase

    init() {
        setup()
    }

    var body: some Scene {
        WindowGroup {
            MainNavigationView()
                .frame(maxWidth: 1000, maxHeight: 500)
                .environmentObject(OrientationInfo())
                .onChange(of: scenePhase) { phase in
                    Self.log.info("Scene change: \(phase)")

                    #if !os(macOS)
                    // schedule a new background task
                    if phase != .active,
                       MainNavigationViewModel.imageConverter.totalDocumentCount.value > 0 {
                        BackgroundTaskScheduler.shared.scheduleTask(with: .pdfProcessing)
                    }
                    #endif
                }
        }
        .windowStyle(CustomWindowStyle())
        #if os(macOS)
        Settings {
            Text("Test")
                .padding()
        }
        #endif
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

        #if !os(macOS)
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
        #endif

        #if !os(macOS) && DEBUG
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
