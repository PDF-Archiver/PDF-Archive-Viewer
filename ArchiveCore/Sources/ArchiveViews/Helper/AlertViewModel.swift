//
//  MainContentViewModel.swift
//  AppClip
//
//  Created by Julian Kahnert on 23.10.20.
//

import Combine
import SwiftUI

public final class AlertViewModel: ObservableObject, Log {
    @Published public var showAlert = false
    @Published public var alertViewModel: AlertDataModel?

    private var disposables = Set<AnyCancellable>()

    public init() {

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
                self.alertViewModel = notification.object as? AlertDataModel
            }
            .store(in: &disposables)
    }
}
