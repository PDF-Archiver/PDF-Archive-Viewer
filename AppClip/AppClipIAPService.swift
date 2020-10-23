//
//  AppClipIAPService.swift
//  AppClip
//
//  Created by Julian Kahnert on 23.10.20.
//

import ArchiveBackend
import StoreKit

final class AppClipIAPService: IAPServiceAPI {
    weak var delegate: IAPServiceDelegate?

    var products = Set<SKProduct>()

    var requestsRunning: Int = 0

    func appUsagePermitted() -> Bool {
        true
    }

    func buyProduct(_ product: SKProduct) {}

    func buyProduct(_ productIdentifier: String) {}

    func restorePurchases() {}
}
