//
//  MainNavigationViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 30.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//
// swiftlint:disable function_body_length

import ArchiveBackend
import Combine
import LoggingKit
import SwiftUI

public final class MainNavigationViewModel: ObservableObject, Log {

    private static let imageConverter = ImageConverter.shared
    private static let iapService = IAPService.shared

    @Published var archiveCategories: [String] = []
    @Published var tagCategories: [String] = []

    @Published var currentTab: Tab = UserDefaults.standard.lastSelectedTab
    @Published var currentOptionalTab: Tab?
    @Published var showTutorial = !UserDefaults.standard.tutorialShown

    var scanViewModel = ScanTabViewModel(imageConverter: imageConverter, iapService: iapService)
    let tagViewModel = TagTabViewModel()
    let archiveViewModel = ArchiveViewModel()
    let moreViewModel = MoreTabViewModel(iapService: iapService)

    let iapViewModel = IAPViewModel(iapService: iapService)

    @Published var showSubscriptionView: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertViewModel: AlertViewModel?

    private var disposables = Set<AnyCancellable>()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    public init() {

        $currentTab
            .map { Optional($0) }
            .removeDuplicates()
            .assign(to: &$currentOptionalTab)

        $currentOptionalTab
            .compactMap { $0 }
            .removeDuplicates()
            .assign(to: &$currentTab)

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
                UserDefaults.standard.lastSelectedTab = selectedTab
                Self.log.info("Changed tab.", metadata: ["selectedTab": "\(selectedTab)"])

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
            .sink { selectedTab in
                self.validateSubscriptionState(of: selectedTab)
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

        ArchiveStore.shared.$years
            .map { years -> [String] in
                let tmp = years.sorted()
                    .reversed()
                    .prefix(5)

                return Array(tmp)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$archiveCategories)

        ArchiveStore.shared.$documents
            .map { _ in
                Array(TagStore.shared.getSortedTags().prefix(10).map(\.localizedCapitalized))
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$tagCategories)

        // TODO: change container!?
        DispatchQueue.global(qos: .userInteractive).async {

            guard let iCloudContainerPath = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                Self.log.assertOrError("Could not find a iCloud Drive url.")
                AlertViewModel.createAndPostNoICloudDrive()
                return
            }

            let path = iCloudContainerPath.appendingPathComponent("Documents")
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
        guard !Self.iapService.appUsagePermitted() && currentTab == .tag else { return }
        currentTab = .archive
    }

    func view(for type: Tab) -> AnyView {
        switch type {
            case .scan:
                return AnyView(ScanTabView(viewModel: scanViewModel))
            case .tag:
                return AnyView(TagTabView(viewModel: tagViewModel))
            case .archive:
                return AnyView(ArchiveView(viewModel: archiveViewModel))
            case .more:
                return AnyView(MoreTabView(viewModel: moreViewModel))
        }
    }

    func selectedArchive(_ category: String) {
        guard let date = DateComponents(calendar: .current, timeZone: .current, year: Int(category)).date else {
            log.assertOrError("Could not create matching date.", metadata: ["input": "\(category)"])
            return
        }

        log.info("Tapped on archive category.")
        currentTab = .archive
        archiveViewModel.selectedFilters = [.year(date)]
    }

    func selectedTag(_ category: String) {
        log.info("Tapped on tag.")
        currentTab = .archive
        let newTagFilter: FilterItem = .tag(category)
        if !archiveViewModel.selectedFilters.contains(newTagFilter) {
            archiveViewModel.selectedFilters.append(newTagFilter)
        }
    }

    // MARK: - Helper Functions

    private func handle(url: URL) {
        log.info("Handling shared document", metadata: ["filetype": "\(url.pathExtension)"])

        do {
            _ = url.startAccessingSecurityScopedResource()
            try Self.imageConverter.handle(url)
//            try StorageHelper.handle(url)
            url.stopAccessingSecurityScopedResource()
        } catch let error {
            url.stopAccessingSecurityScopedResource()
            log.error("Unable to handle file.", metadata: ["filetype": "\(url.pathExtension)", "error": "\(error.localizedDescription)"])
            try? FileManager.default.removeItem(at: url)

            AlertViewModel.createAndPost(message: error, primaryButtonTitle: "OK")
        }
    }

    private func validateSubscriptionState(of selectedTab: Tab) {
        self.showSubscriptionView = !Self.iapService.appUsagePermitted() && selectedTab == .tag
    }
}
