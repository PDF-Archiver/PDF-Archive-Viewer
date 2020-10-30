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
import SwiftUI

public final class MainNavigationViewModel: ObservableObject, Log {

    public static let imageConverter = ImageConverter(getDocumentDestination: { PathManager.shared.untaggedURL },
                                                      shouldStartBackgroundTask: true)
    public static let iapService = IAPService()

    @Published var error: Error?

    @Published var archiveCategories: [String] = []
    @Published var tagCategories: [String] = []

    @Published var currentTab: Tab = UserDefaults.appGroup.lastSelectedTab
    @Published var currentOptionalTab: Tab?
    @Published var showTutorial = !UserDefaults.appGroup.tutorialShown

    var scanViewModel = ScanTabViewModel(imageConverter: imageConverter, iapService: iapService, documentsFinishedHandler: scanFinished)
    let tagViewModel = TagTabViewModel()
    let archiveViewModel = ArchiveViewModel()
    let moreViewModel = MoreTabViewModel(iapService: iapService)

    let iapViewModel = IAPViewModel(iapService: iapService)

    @Published var showSubscriptionView: Bool = false

    private var disposables = Set<AnyCancellable>()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    public init() {

        Self.iapService.$error
            .assign(to: &$error)

        Self.imageConverter.$error
            .assign(to: &$error)

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
        if !UserDefaults.appGroup.tutorialShown {
            currentTab = .archive
        }

        $currentTab
            .dropFirst()
            .removeDuplicates()
            .sink { selectedTab in
                // save the selected index for the next app start
                UserDefaults.appGroup.lastSelectedTab = selectedTab
                Self.log.info("Changed tab.", metadata: ["selectedTab": "\(selectedTab)"])

                self.selectionFeedback.prepare()
                self.selectionFeedback.selectionChanged()
            }
            .store(in: &disposables)

        // MARK: Intro
        $showTutorial
            .sink { shouldPresentTutorial in
                UserDefaults.appGroup.tutorialShown = !shouldPresentTutorial
            }
            .store(in: &disposables)

        NotificationCenter.default.publisher(for: .introChanges)
            .sink { notification in
                self.showTutorial = (notification.object as? Bool) ?? false
            }
            .store(in: &disposables)

        // MARK: Subscription
        Self.iapService.appUsagePermittedPublisher
            .removeDuplicates()
            .combineLatest($currentTab)
            .receive(on: DispatchQueue.main)
            .sink { (_, selectedTab) in
                self.showSubscriptionView = !Self.iapService.appUsagePermitted && selectedTab == .tag
            }
            .store(in: &disposables)

        NotificationCenter.default.publisher(for: .showSubscriptionView)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.showSubscriptionView = true
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

            guard let iCloudContainerPath = PathManager.iCloudDriveURL else {
                Self.log.error("Could not find a iCloud Drive url.")
                AlertDataModel.createAndPostNoICloudDrive()
                return
            }

            ArchiveStore.shared.update(archiveFolder: iCloudContainerPath, untaggedFolders: [iCloudContainerPath.appendingPathComponent("untagged")])
        }

        // get documents from ShareExtension and AppClip
        let extensionURLs = (try? FileManager.default.contentsOfDirectory(at: PathManager.extensionTempPdfURL, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])) ?? []
        let appClipURLs = (try? FileManager.default.contentsOfDirectory(at: PathManager.appClipTempPdfURL, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])) ?? []
        let urls = [extensionURLs, appClipURLs]
            .flatMap { $0 }
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
            log.errorAndAssert("Could not create matching date.", metadata: ["input": "\(category)"])
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

    func handleIAPViewDismiss() {
        guard !Self.iapService.appUsagePermitted else { return }
        currentTab = .scan
    }

    // MARK: - Helper Functions

    private static func scanFinished() {
        guard !UserDefaults.appGroup.firstDocumentScanAlertPresented else { return }
        UserDefaults.appGroup.firstDocumentScanAlertPresented = true

        AlertDataModel.createAndPost(title: "First Scan processed! 🙂",
                                     message: "The first document was processed successfully and is now waiting for you in the 'Tag' tab.\n\n📄   ➡️   🗄",
                                     primaryButtonTitle: "OK")
    }

    private func handle(url: URL) {
        log.info("Handling shared document", metadata: ["filetype": "\(url.pathExtension)"])

        do {
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            _ = url.startAccessingSecurityScopedResource()
            try Self.imageConverter.handle(url)
        } catch {
            log.error("Unable to handle file.", metadata: ["filetype": "\(url.pathExtension)", "error": "\(error.localizedDescription)"])
            try? FileManager.default.removeItem(at: url)

            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
}
