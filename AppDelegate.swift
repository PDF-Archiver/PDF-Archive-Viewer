//
//  AppDelegate.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 29.12.18.
//  Copyright © 2018 Julian Kahnert. All rights reserved.
//

import Diagnostics
import Foundation
import Logging
import Sentry
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate, Log {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

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

            // schedule a new background task
            if MainNavigationViewModel.imageConverter.totalDocumentCount.value > 0 {
                BackgroundTaskScheduler.shared.scheduleTask(with: .pdfProcessing)
            }

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

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        DiagnosticsLogger.log(message: "App did enter background.")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        DiagnosticsLogger.log(message: "Did receive memory warning.")
    }
}
