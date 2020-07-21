//
//  IAPHelper.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 22.06.18.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//  The structure is base on: https://www.raywenderlich.com/122144/in-app-purchase-tutorial
//

import LogModel
import LoggingKit
import StoreKit
import SwiftyStoreKit

public protocol IAPServiceDelegate: AnyObject {
    func found(products: Set<SKProduct>)
    func found(requestsRunning: Int)
}

// setup default implementations for this delegate
public extension IAPServiceDelegate {
    func found(products: Set<SKProduct>) {}
    func found(requestsRunning: Int) {}
}

public class IAPService: NSObject, Log {

    private static let productIdentifiers = Set(["SUBSCRIPTION_MONTHLY_IOS", "SUBSCRIPTION_YEARLY_IOS_NEW"])

    private var expiryDate: Date? {
        get {
            let expiryDate = UserDefaults.standard.subscriptionExpiryDate
            log.debug("Getting new expiry date: \(expiryDate?.description ?? "")")
            return expiryDate
        }
        set {
            log.debug("Setting new expiry date: \(newValue?.description ?? "")")
            UserDefaults.standard.subscriptionExpiryDate = newValue
        }
    }

    public weak var delegate: IAPServiceDelegate?

    public private(set) var products = Set<SKProduct>() {
        didSet { delegate?.found(products: self.products) }
    }
    public private(set) var requestsRunning: Int = 0 {
        didSet { delegate?.found(requestsRunning: requestsRunning) }
    }

    override public init() {

        super.init()

        // Start SwiftyStoreKit and complete transactions
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    // Unlock content

                default:
                    break // do nothing
                }
            }
        }

        // get products
        requestProducts()

        // release only: fetch receipt
        if AppEnvironment.get() == .production {
            _ = self.appUsagePermitted(appStart: true)
        }
    }

    // MARK: - StoreKit API

    public func appUsagePermitted(appStart: Bool = false) -> Bool {

        // debug/simulator/testflight: app usage is always permitted
        let environment = AppEnvironment.get()
        if environment == .develop || environment == .testflight {
            return true
        }

        if let expiryDate = self.expiryDate,
            expiryDate > Date() {
            return true

        } else {

            // could not found a valid expiryDate locally, so we have to fetch receipts and validate them
            // in a background thread
            DispatchQueue.global(qos: .userInitiated).async {
                // get local or remote receipt
                self.fetchReceipt(appStart: appStart)

                // validate receipt and check expiration date
                self.saveNewExpiryDateOfReceipt()
            }
            return false
        }
    }

    public func buyProduct(_ product: SKProduct) {
        log.info("Buying \(product.productIdentifier) ...")

        requestsRunning += 1
        SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
            self.requestsRunning -= 1
            switch result {
            case .success(let purchase):
                Self.log.info("Purchse successfull: \(purchase.productId)")
                self.fetchReceipt()

                // validate receipt and save new expiry date
                self.saveNewExpiryDateOfReceipt()

            case .error(let error):
                Self.log.error("Purchase failed with error.", metadata: ["error": "\(error.localizedDescription)"])
            }
        }
    }

    public func buyProduct(_ productIdentifier: String) {
        if let product = products.first(where: { $0.productIdentifier == productIdentifier }) {
            buyProduct(product)
        } else {
            log.error("Could not find any product for id: \(productIdentifier)")
        }
    }

    public func restorePurchases() {
        requestsRunning += 1
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            self.requestsRunning -= 1
            if !results.restoreFailedPurchases.isEmpty {
                Self.log.error("Restore Failed: \(results.restoreFailedPurchases)")
            } else if !results.restoredPurchases.isEmpty {
                Self.log.debug("Restore Success: \(results.restoredPurchases)")
            } else {
                Self.log.info("Nothing to Restore")
            }
        }
    }

    // MARK: - Helper Functions

    fileprivate func saveNewExpiryDateOfReceipt(with service: AppleReceiptValidator.VerifyReceiptURLType = .production) {
        log.info("external start")

        // create apple validator
        let appleValidator = AppleReceiptValidator(service: service, sharedSecret: Constants.appStoreConnectSharedSecret)

        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            defer {
                Self.log.info("Internal end")
            }
            Self.log.info("Internal start")

            switch result {
            case .success(let receipt):

                for productId in IAPService.productIdentifiers {
                    // Verify the purchase of a Subscription
                    let purchaseResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: productId, inReceipt: receipt)

                    switch purchaseResult {
                    case .purchased(let expiryDate, _):

                        Self.log.debug("Product (id: \(productId)) is valid until \(expiryDate.description)")

                        // set new expiration date
                        self.expiryDate = expiryDate

                        // poste subscription change
                        NotificationCenter.default.post(.subscriptionChanges)

                        return

                    case .expired(let expiryDate, _):
                        Self.log.debug("Product (id: \(productId)) has expired since \(expiryDate.description)")
                    case .notPurchased:
                        Self.log.debug("The user has never purchased \(productId)")
                    }
                }

            case .error(let error):
                Self.log.error("Receipt verification failed", metadata: ["error": "\(error.localizedDescription)"])
                if service == .production {
                    self.saveNewExpiryDateOfReceipt(with: .sandbox)
                }
            }
        }
    }

    fileprivate func fetchReceipt(forceRefresh: Bool = false, appStart: Bool = false) {

        // refresh receipt if not reachable
        SwiftyStoreKit.fetchReceipt(forceRefresh: forceRefresh) { result in

            switch result {
            case .success:
                Self.log.debug("Fetching receipt was successful.")
            case .error(let error):
                Self.log.debug("Fetch receipt failed.", metadata: ["error": "\(error.localizedDescription)"])
                if appStart {
                    Self.log.error("Receipt not found, exit the app!")
                    exit(173)

                } else if !forceRefresh {
                    // we do not run in an infinite recurse situation since this will only be reached, if no forceRefresh was issued
                    Self.log.info("Receipt not found, refreshing receipt.")
                    self.fetchReceipt(forceRefresh: true, appStart: false)
                }
            }
        }
    }

    private func requestProducts() {
        requestsRunning += 1
        SwiftyStoreKit.retrieveProductsInfo(IAPService.productIdentifiers) { result in
            self.requestsRunning -= 1
            self.products = result.retrievedProducts

            if !result.retrievedProducts.isEmpty {
                Self.log.debug("Found \(result.retrievedProducts.count) products.")
            } else if let invalidProductId = result.invalidProductIDs.first {
                Self.log.info("Invalid product identifier: \(invalidProductId)")
            } else {
                Self.log.info("Retrieving product infos errored: \(result.error?.localizedDescription ?? "")")
            }
        }
    }
}
