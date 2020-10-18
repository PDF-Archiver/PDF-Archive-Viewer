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
import LogModel
import Sentry
import SwiftUI

@main
struct PDFArchiverApp: App {

    // swiftlint:disable weak_delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private var isCurrentlyProcessing = Atomic(false)

    var body: some Scene {
        WindowGroup {
            MainNavigationView()
                .environmentObject(OrientationInfo())
        }
//        #if os(macOS)
//        Settings {
//            Text("Test")
//        }
//        #endif
    }
}
