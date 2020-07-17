//
//  AppDelegate.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 29.12.18.
//  Copyright © 2018 Julian Kahnert. All rights reserved.
//

import Diagnostics
import LogModel
import MetricKit
import os.log
import Sentry
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DispatchQueue.global().async {

            // TODO: how do we do this with SwiftUI only
            // start logging service by sending old events (if needed)
            //Log.sendOrPersistInBackground(application)

            // start IAP service
            _ = IAP.service

            // start document service
            _ = ArchiveStore.shared
//            _ = DocumentService.archive
//            _ = DocumentService.documentsQuery
        }

        DispatchQueue.global(qos: .background).async {

        }

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

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // send logs in background
        Log.sendOrPersistInBackground(application)
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Log.send(.warning, "Did receive memory warning.")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        MXMetricManager.shared.remove(self)
    }
}

extension AppDelegate: MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {

            var extra: [String: String] = [:]
            extra["appBuildVersion"] = payload.metaData?.applicationBuildVersion
            extra["osVersion"] = payload.metaData?.osVersion
            extra["regionFormat"] = payload.metaData?.regionFormat
            extra["deviceType"] = payload.metaData?.deviceType
            extra["appVersion"] = payload.latestApplicationVersion
            extra["timeStampBegin"] = payload.timeStampBegin.description
            extra["timeStampEnd"] = payload.timeStampEnd.description
            extra["cumulativeCPUTime"] = payload.cpuMetrics?.cumulativeCPUTime.description
            extra["raw"] = String(data: payload.jsonRepresentation(), encoding: .utf8)

            Log.send(.info, "MXMetricPayload", extra: extra)
        }
    }
}
