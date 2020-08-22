//
//  MainTabViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 30.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//
// swiftlint:disable function_body_length

import Combine
import LoggingKit
import SwiftUI

class MainTabViewModel: ObservableObject, Log {
    @Published var currentTab = UserDefaults.standard.lastSelectedTabIndex
    @Published var showTutorial = !UserDefaults.standard.tutorialShown

    var scanViewModel = ScanTabViewModel()
    let tagViewModel = TagTabViewModel()
    let archiveViewModel = ArchiveViewModel()
    let moreViewModel = MoreTabViewModel()

    let iapViewModel = IAPViewModel()

    @Published var showSubscriptionView: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertViewModel: AlertViewModel?

    private var disposables = Set<AnyCancellable>()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    init() {

        scanViewModel.objectWillChange
            .sink { _ in
                // bubble up the change from the nested view model
                self.objectWillChange.send()
            }
            .store(in: &disposables)

        // MARK: UserDefaults
        if !UserDefaults.standard.tutorialShown {
            currentTab = .archive
        }

        $currentTab
            .dropFirst()
            .removeDuplicates()
            .sink { selectedTab in
                // save the selected index for the next app start
                UserDefaults.standard.lastSelectedTabIndex = selectedTab
                Self.log.info("Changed tab.", metadata: ["selectedTab": "\(selectedTab.rawValue)"])

                self.selectionFeedback.prepare()
                self.selectionFeedback.selectionChanged()
            }
            .store(in: &disposables)

        // MARK: Intro
        $showTutorial
            .sink { shouldPresentTutorial in
                UserDefaults.standard.tutorialShown = !shouldPresentTutorial
            }
            .store(in: &disposables)

        NotificationCenter.default.publisher(for: .introChanges)
            .sink { notification in
                self.showTutorial = (notification.object as? Bool) ?? false
            }
            .store(in: &disposables)

        // MARK: Subscription
        $currentTab
            .sink { selectedIndex in
                self.validateSubscriptionState(of: selectedIndex)
            }
            .store(in: &disposables)

        NotificationCenter.default.publisher(for: .subscriptionChanges)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.showSubscriptionDismissed()
                self.validateSubscriptionState(of: self.currentTab)
            }
            .store(in: &disposables)

        NotificationCenter.default.publisher(for: .showSubscriptionView)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.showSubscriptionView = true
            }
            .store(in: &disposables)

        // MARK: Alerts
        $alertViewModel
            .receive(on: DispatchQueue.main)
            .sink { viewModel in
                self.showAlert = viewModel != nil
            }
            .store(in: &disposables)

        NotificationCenter.default.publisher(for: .showError)
            .receive(on: DispatchQueue.main)
            .sink { notification in
                self.alertViewModel = notification.object as? AlertViewModel
            }
            .store(in: &disposables)

        // TODO: change container!?
        DispatchQueue.global(qos: .userInteractive).async {

//            guard let path = StorageHelper.Paths.archivePath else {
//                assertionFailure("Could not find a iCloud Drive url.")
//                AlertViewModel.createAndPost(title: "Attention",
//                                             message: "Could not find iCloud Drive.",
//                                             primaryButtonTitle: "OK")
//                return
//            }

            let path = FileManager.default.url(forUbiquityContainerIdentifier: nil)!.appendingPathComponent("Documents")
            ArchiveStore.shared.update(archiveFolder: path, untaggedFolders: [path.appendingPathComponent("untagged")])
        }

        // TODO: refactor/move this
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.sharedContainerIdentifier) else {
            log.critical("Failed to get url for forSecurityApplicationGroupIdentifier.")
            return
        }
        let urls = ((try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])) ?? [])
            .filter { !$0.hasDirectoryPath }

        if !urls.isEmpty {
            DispatchQueue.main.async {

                // show scan tab with document processing, after importing a document
                self.currentTab = .scan
            }
        }

        for url in urls {
            self.handle(url: url)
        }
    }

    func showSubscriptionDismissed() {
        guard !IAP.service.appUsagePermitted() && currentTab == .tag else { return }
        currentTab = .archive
    }

    // MARK: - Helper Functions

    private func handle(url: URL) {
        log.info("Handling shared document", metadata: ["filetype": "\(url.pathExtension)"])

        do {
            _ = url.startAccessingSecurityScopedResource()
            try StorageHelper.handle(url)
            url.stopAccessingSecurityScopedResource()
        } catch let error {
            url.stopAccessingSecurityScopedResource()
            log.error("Unable to handle file.", metadata: ["filetype": "\(url.pathExtension)", "error": "\(error.localizedDescription)"])
            try? FileManager.default.removeItem(at: url)

            AlertViewModel.createAndPost(message: error, primaryButtonTitle: "OK")
        }
    }

    private func validateSubscriptionState(of selectedTab: MainTabView.Tabs) {
        self.showSubscriptionView = !IAP.service.appUsagePermitted() && selectedTab == .tag
    }
}
