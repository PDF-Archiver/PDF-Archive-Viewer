//
//  PDFArchiverApp.swift
//  Shared
//
//  Created by Julian Kahnert on 24.06.20.
//

@_exported import ArchiveCore

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
            MainTabView()
                .accentColor(Color(.paDarkGray))
                .environmentObject(OrientationInfo())
        }
//        #if os(macOS)
//        Settings {
//            Text("Test")
//        }
//        #endif
    }
}
