//
//  AppDelegate.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 29.12.18.
//  Copyright © 2018 Julian Kahnert. All rights reserved.
//

import Diagnostics
import Foundation
import LogModel
import Logging
import LoggingKit
import MetricKit
import Sentry
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate, Log {

    private static let logger: RestLogger = {
//        let endpoint = URL(string: "https://logs-develop.pdf-archiver.io/v1/addBatch")!
        let endpoint = URL(string: "https://logs.pdf-archiver.io/v1/addBatch")!
        var logger = RestLogger(endpoint: endpoint,
                                username: Constants.logUser,
                                password: Constants.logPassword,
                                shouldSend: {
                                    AppEnvironment.get() != .develop
//                                        true
                                })

        // set the level
        logger.logLevel = .warning
        return logger
    }()

    private var backgroundCompletionHandler: (() -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        LoggingSystem.bootstrap { label in

            var sysLogger = StreamLogHandler.standardOutput(label: label)
            sysLogger.logLevel = .trace
            return MultiplexLogHandler([sysLogger, Self.logger])
        }

        DispatchQueue.global().async {

            // start document service
            _ = ArchiveStore.shared

            // schedule a new background task
            if ImageConverter.shared.totalDocumentCount.value > 0 {
                BackgroundTaskScheduler.shared.scheduleTask(with: .pdfProcessing)
            }

        }

        do {
            try DiagnosticsLogger.setup()
        } catch {
            log.warning("Failed to setup the Diagnostics Logger")
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
        // persist all logs when the app enters background
        sendOrPersistLogs()
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        log.warning("Did receive memory warning.")
        sendOrPersistLogs()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MXMetricManager.shared.remove(self)
    }

    // MARK: Log handling

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // save the completion handler for the next time the app is active
        backgroundCompletionHandler = completionHandler
    }

    private func sendOrPersistLogs() {
        // send logs in background
        // TODO: test sending logs
        let config = URLSessionConfiguration.background(withIdentifier: "LogUpload")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        let backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        Self.logger.sendOrPersist(with: backgroundSession)
    }
}
extension AppDelegate: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            // handle the completion of the background url session and call the completion handler
            (UIApplication.shared.delegate as? AppDelegate)?.backgroundCompletionHandler?()
        }
    }
}

extension AppDelegate: MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {

            log.info("MXMetricPayload", metadata: [
                "appBuildVersion": "\(payload.metaData?.applicationBuildVersion ?? "")",
                "osVersion": "\(payload.metaData?.osVersion ?? "")",
                "regionFormat": "\(payload.metaData?.regionFormat ?? "")",
                "deviceType": "\(payload.metaData?.deviceType ?? "")",
                "appVersion": "\(payload.latestApplicationVersion)",
                "timeStampBegin": "\(payload.timeStampBegin.description)",
                "timeStampEnd": "\(payload.timeStampEnd.description)",
                "cumulativeCPUTime": "\(payload.cpuMetrics?.cumulativeCPUTime.description ?? "")",
                "raw": "\(String(data: payload.jsonRepresentation(), encoding: .utf8) ?? "")"
            ])
        }
    }
}
