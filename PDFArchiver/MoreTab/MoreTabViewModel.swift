//
//  MoreTabViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 13.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Combine
import MessageUI
import SwiftUI

class MoreTabViewModel: ObservableObject {

    static let mailRecipients = ["support@pdf-archiver.io"]
    static let mailSubject = "PDF Archiver: iOS Support"
    
    static func getCurrentStatus() -> LocalizedStringKey {
        IAP.service.appUsagePermitted() ? "Active ✅" : "Inactive ❌"
    }

    @Published var qualities: [LocalizedStringKey]  = ["100% - Lossless 🤯", "75% - Good 👌 (Default)", "50% - Normal 👍", "25% - Small 💾"]
    @Published var selectedQualityIndex = UserDefaults.PDFQuality.toIndex(UserDefaults.standard.pdfQuality)

    @Published var isShowingMailView: Bool = false
    @Published var result: Result<MFMailComposeResult, Error>?
    @Published var subscriptionStatus: LocalizedStringKey

    private var disposables = Set<AnyCancellable>()

    init() {
        subscriptionStatus = Self.getCurrentStatus()
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
        Log.send(.info, "More table view show: intro")
//        NotificationCenter.default.post(name: .introChanges, object: true)
    }

    func showPermissions() {
        Log.send(.info, "More table view show: app permissions")
        guard let link = URL(string: UIApplication.openSettingsURLString) else { fatalError("Could not find settings url!") }
        UIApplication.shared.open(link)
    }

    func resetApp() {
        Log.send(.info, "More table view show: reset app")
        // remove all temporary files
        if let tempImagePath = StorageHelper.Paths.tempImagePath {
            try? FileManager.default.removeItem(at: tempImagePath)
        } else {
            Log.send(.error, "Could not find tempImagePath.")
        }

        // remove all user defaults
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        } else {
            Log.send(.error, "Bundle Identifier not found.")
        }

        AlertViewModel.createAndPost(title: "Reset App", message: "Please restart the app to complete the reset.", primaryButtonTitle: "OK")
    }

    var manageSubscriptionUrl: URL {
        URL(string: "https://apps.apple.com/account/subscriptions")!
    }

    var macOSAppUrl: URL {
        URL(string: "https://macos.pdf-archiver.io")!
    }

    var privacyPolicyUrl: URL {
        URL(string: NSLocalizedString("MoreTableViewController.privacyPolicyCell.url", comment: ""))!
    }

    var imprintUrl: URL {
        URL(string: NSLocalizedString("MoreTableViewController.imprintCell.url", comment: ""))!
    }

    func showSupport() {
        Log.send(.info, "More table view show: support")
        if MFMailComposeViewController.canSendMail() {
            isShowingMailView = true
        } else {
            guard let url = URL(string: "https://pdf-archiver.io/faq") else { fatalError("Could not generate the FAQ url.") }
            UIApplication.shared.open(url)
        }
    }
    
    func updateSubscription() {
        subscriptionStatus = MoreTabViewModel.getCurrentStatus()
    }
}
