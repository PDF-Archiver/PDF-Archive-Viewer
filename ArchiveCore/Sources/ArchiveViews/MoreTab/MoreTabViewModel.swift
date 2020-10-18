//
//  MoreTabViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 13.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//
// swiftlint:disable force_unwrapping

import Combine
import MessageUI
import LoggingKit
import SwiftUI

final class MoreTabViewModel: ObservableObject, Log {

    static let mailRecipients = ["support@pdf-archiver.io"]
    static let mailSubject = "PDF Archiver: iOS Support"

    @Published var qualities: [LocalizedStringKey]  = ["100% - Lossless 🤯", "75% - Good 👌 (Default)", "50% - Normal 👍", "25% - Small 💾"]
    @Published var selectedQualityIndex = UserDefaults.PDFQuality.toIndex(UserDefaults.standard.pdfQuality)

    @Published var isShowingMailView: Bool = false
    @Published var result: Result<MFMailComposeResult, Error>?
    @Published var subscriptionStatus: LocalizedStringKey = "Inactive ❌"

    private let iapService: IAPServiceAPI
    private var disposables = Set<AnyCancellable>()

    init(iapService: IAPServiceAPI) {
        self.iapService = iapService
        subscriptionStatus = getCurrentStatus()
        $selectedQualityIndex
            .sink { selectedQuality in
                UserDefaults.standard.pdfQuality = UserDefaults.PDFQuality.allCases[selectedQuality]
            }
            .store(in: &disposables)

        NotificationCenter.default.publisher(for: .subscriptionChanges)
            .sink { _ in
                self.updateSubscription()
            }
            .store(in: &disposables)
    }

    func showIntro() {
        log.info("More table view show: intro")
        NotificationCenter.default.post(name: .introChanges, object: true)
    }

    func showPermissions() {
        log.info("More table view show: app permissions")
        guard let link = URL(string: UIApplication.openSettingsURLString) else { fatalError("Could not find settings url!") }
        UIApplication.shared.open(link)
    }

    func resetApp() {
        log.info("More table view show: reset app")
        // remove all temporary files
        if let tempImagePath = Paths.tempImagePath {
            try? FileManager.default.removeItem(at: tempImagePath)
        } else {
            log.error("Could not find tempImagePath.")
        }

        // remove all user defaults
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        } else {
            log.error("Bundle Identifier not found.")
        }

        AlertViewModel.createAndPost(title: "Reset App", message: "Please restart the app to complete the reset.", primaryButtonTitle: "OK")
    }

    var manageSubscriptionUrl: URL {
        URL(string: "https://apps.apple.com/account/subscriptions")!
    }

    var macOSAppUrl: URL {
        URL(string: "https://macos.pdf-archiver.io")!
    }

    func showSupport() {
        log.info("More table view show: support")
        if MFMailComposeViewController.canSendMail() {
            isShowingMailView = true
        } else {
            guard let url = URL(string: "https://pdf-archiver.io/faq") else { fatalError("Could not generate the FAQ url.") }
            UIApplication.shared.open(url)
        }
    }

    func updateSubscription() {
        subscriptionStatus = getCurrentStatus()
    }

    private func getCurrentStatus() -> LocalizedStringKey {
        iapService.appUsagePermitted() ? "Active ✅" : "Inactive ❌"
    }
}
