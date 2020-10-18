//
//  IAPViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 13.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Combine
import LoggingKit
import StoreKit
import SwiftUI
import SwiftyStoreKit

final class IAPViewModel: ObservableObject, Log {
    @Published var level1Name = "Level 1"
    @Published var level2Name = "Level 2"

    private let iapService: IAPServiceAPI

    init(iapService: IAPServiceAPI) {
        self.iapService = iapService

        // setup delegate
        self.iapService.delegate = self

        // setup button names
        guard !self.iapService.products.isEmpty else { return }
        updateButtonNames(with: self.iapService.products)
    }

    func tapped(button: IAPButton) {

        switch button {
        case .level1:
            log.info("SubscriptionViewController - buy: Monthly subscription.")
            iapService.buyProduct("SUBSCRIPTION_MONTHLY_IOS")
            cancel()
        case .level2:
            log.info("SubscriptionViewController - buy: Yearly subscription.")
            iapService.buyProduct("SUBSCRIPTION_YEARLY_IOS_NEW")
            cancel()
        case .restore:
            log.info("SubscriptionViewController - Restore purchases.")
            iapService.restorePurchases()
            AlertViewModel.createAndPost(title: "Subscription",
                                         message: "Active subscriptions will be restored from the App Store.\nPlease contact me if you have any problems:\nMore > Support",
                                         primaryButtonTitle: "OK",
                                         completion: { self.cancel() })
        case .cancel:
            log.info("SubscriptionViewController - Cancel subscription view.")
            cancel()
        }
    }

    private func cancel() {
        NotificationCenter.default.post(.subscriptionChanges)
    }

    private func updateButtonNames(with products: Set<SKProduct>) {
        for product in products {
            switch product.productIdentifier {
            case "SUBSCRIPTION_MONTHLY_IOS":
                guard let localizedPrice = product.localizedPrice else { continue }
                level1Name = localizedPrice + " " + NSLocalizedString("per_month", comment: "")
            case "SUBSCRIPTION_YEARLY_IOS_NEW":
                guard let localizedPrice = product.localizedPrice else { continue }
                level2Name = localizedPrice + " " + NSLocalizedString("per_year", comment: "")
            default:
                Self.log.error("Could not find product in IAP.", metadata: ["product_name": "\(product.localizedDescription)"])
            }
        }
    }
}

extension IAPViewModel {
    enum IAPButton: String, CaseIterable {
        case level1
        case level2
        case restore
        case cancel
    }
}

extension IAPViewModel: IAPServiceDelegate {
    func unlocked() {
        tapped(button: .cancel)
    }

    func found(products: Set<SKProduct>) {
        updateButtonNames(with: products)
    }
}
