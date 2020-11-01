//
//  ScanTabViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 02.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import AVKit
import Combine
import Foundation
import SwiftUI
import VisionKit

public final class ScanTabViewModel: ObservableObject, Log {
    @Published public private(set) var error: Error?
    @Published public var showDocumentScan: Bool = false
    @Published public private(set) var progressValue: CGFloat = 0.0
    @Published public private(set) var progressLabel: String = " "

    private let imageConverter: ImageConverterAPI
    private let iapService: IAPServiceAPI
    private let documentsFinishedHandler: (inout Error?) -> Void

    private var lastProgressValue: CGFloat?
    private var disposables = Set<AnyCancellable>()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    public init(imageConverter: ImageConverterAPI, iapService: IAPServiceAPI, documentsFinishedHandler: @escaping (inout Error?) -> Void) {
        self.imageConverter = imageConverter
        self.iapService = iapService
        self.documentsFinishedHandler = documentsFinishedHandler

        // show the processing indicator, if documents are currently processed
        if imageConverter.totalDocumentCount.value != 0 {
            updateProcessingIndicator(with: 0)
        }

        // trigger processing (if temp images exist)
        triggerImageProcessing()

        NotificationCenter.default.publisher(for: .imageProcessingQueue)
            .sink { [weak self] notification in
                guard let self = self else { return }
                let documentProgress = notification.object as? Float
                self.updateProcessingIndicator(with: documentProgress)

                guard documentProgress == nil else { return }

                // there might be a better way for this inout workaround
                var error: Error?
                self.documentsFinishedHandler(&error)
                if let error = error {
                    self.error = error
                }
            }
            .store(in: &disposables)
    }

    public func startScanning() {
        notificationFeedback.prepare()
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
            case .authorized:
                log.info("Start scanning a document.")
                showDocumentScan = true
                notificationFeedback.notificationOccurred(.success)

                // stop current image processing
                imageConverter.stopProcessing()

            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    guard granted else { return }
                    DispatchQueue.main.async {
                        self.startScanning()
                    }
                }

            case .denied, .restricted:
                log.info("Authorization status blocks camera access. Switch to preferences.")

                notificationFeedback.notificationOccurred(.warning)
                error = AlertDataModel.createAndPost(title: "Need Camera Access",
                                             message: "Camera access is required to scan documents.",
                                             primaryButton: .default(Text("Grant Access"),
                                                                     action: {
                                                                        guard let settingsAppURL = URL(string: UIApplication.openSettingsURLString) else { fatalError("Could not find settings url!") }
                                                                        UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
                                             }),
                                             secondaryButton: .cancel())

            @unknown default:
                preconditionFailure("This authorization status is unkown.")
        }
    }

    public func process(_ images: [UIImage]) {
        assert(!Thread.isMainThread, "This might take some time and should not be executed on the main thread.")

        // validate subscription
        guard testAppUsagePermitted() else { return }

        // show processing indicator instantly
        updateProcessingIndicator(with: 0)

        // save images in reversed order to fix the API output order
        do {
            defer {
                // notify ImageConverter even if the image saving has failed
                triggerImageProcessing()
            }
            try StorageHelper.save(images)
        } catch {
            assertionFailure("Could not save temp images with error:\n\(error)")
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }

    // MARK: - Helper Functions

    private func triggerImageProcessing() {
        do {
            try imageConverter.startProcessing()
        } catch {
            log.error("Failed to start processing.", metadata: ["error": "\(error)"])
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }

    private func updateProcessingIndicator(with documentProgress: Float?) {
        DispatchQueue.main.async {

            // we do not need a progress view, if the number of total documents is 0
            let totalDocuments = self.imageConverter.totalDocumentCount.value
            let tmpDocumentProgress = totalDocuments == 0 ? nil : documentProgress

            if let documentProgress = tmpDocumentProgress {

                let completedDocuments = totalDocuments - self.imageConverter.getOperationCount()
                let progressString = "\(min(completedDocuments + 1, totalDocuments))/\(totalDocuments) (\(Int(documentProgress * 100))%)"

                self.progressValue = min((CGFloat(completedDocuments) + CGFloat(documentProgress)) / CGFloat(totalDocuments), 1)
                self.progressLabel = NSLocalizedString("ScanViewController.processing", comment: "") + progressString
            } else {
                self.progressValue = 0
                self.progressLabel = NSLocalizedString("ScanViewController.processing", comment: "") + "0%"
            }
        }
    }

    private func testAppUsagePermitted() -> Bool {

        let isPermitted = iapService.appUsagePermitted

        // show subscription view controller, if no subscription was found
        if !isPermitted {
            DispatchQueue.main.async {
                self.error = AlertDataModel.createAndPost(title: "No Subscription",
                                                          message: "No active subscription could be found. Your document will therefore not be saved.\nPlease support the app and subscribe.",
                                                          primaryButton: .default(Text("Activate"), action: {
                                                            // show the subscription view
                                                            NotificationCenter.default.post(.showSubscriptionView)
                                                          }),
                                                          secondaryButton: .cancel())
            }
        }

        return isPermitted
    }
}
