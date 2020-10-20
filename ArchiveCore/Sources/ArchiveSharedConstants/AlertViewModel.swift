//
//  AlertViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 19.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Foundation
import SwiftUI

public struct AlertViewModel {
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey
    public let primaryButton: Alert.Button
    public let secondaryButton: Alert.Button?
}

extension AlertViewModel {

    public static func createAndPost(title: LocalizedStringKey, message: LocalizedStringKey, primaryButtonTitle: LocalizedStringKey, completion: (() -> Void)? = nil) {

        let primaryButton: Alert.Button
        if let completion = completion {
            primaryButton = .default(Text(primaryButtonTitle),
                                     action: completion)
        } else {
            primaryButton = .default(Text(primaryButtonTitle))
        }
        let viewModel = AlertViewModel(title: title,
                                       message: message,
                                       primaryButton: primaryButton,
                                       secondaryButton: nil)
        NotificationCenter.default.post(name: .showError, object: viewModel)
    }

    public static func createAndPost(title predefinedTitle: LocalizedStringKey? = nil, message error: Error, primaryButtonTitle: LocalizedStringKey) {
        let defaultTitle = "Something went wrong!"
        let title: String
        let message: String
        if let error = error as? LocalizedError {
            title = error.errorDescription ?? defaultTitle
            message = [
                error.failureReason,
                error.recoverySuggestion]
                .compactMap { $0 }
                .joined(separator: "\n\n")
        } else {
            title = defaultTitle
            message = error.localizedDescription
        }

        let viewModel = AlertViewModel(title: predefinedTitle ?? LocalizedStringKey(title),
                                       message: LocalizedStringKey(message),
                                       primaryButton: .default(Text(primaryButtonTitle)),
                                       secondaryButton: nil)
        NotificationCenter.default.post(name: .showError, object: viewModel)
    }

    public static func createAndPost(title: LocalizedStringKey, message: LocalizedStringKey, primaryButton: Alert.Button, secondaryButton: Alert.Button) {
        let viewModel = AlertViewModel(title: title,
                                       message: message,
                                       primaryButton: primaryButton,
                                       secondaryButton: secondaryButton)
        NotificationCenter.default.post(name: .showError, object: viewModel)
    }

    public static func createAndPostNoICloudDrive() {
        createAndPost(title: "Attention",
                      message: "Could not find iCloud Drive.",
                      primaryButtonTitle: "OK")
    }
}
