//
//  IAPService.swift
//  
//
//  Created by Julian Kahnert on 28.10.20.
//

import ArchiveSharedConstants
import Combine
import StoreKit
import TPInAppReceipt

public final class IAPService: NSObject, Log {

    private static var isInitialized = false

    @Published public private(set) var products = Set<SKProduct>()
    @Published public private(set) var appUsagePermitted = false

    private let paymentQueue = SKPaymentQueue.default()
    private var productsRequest: SKProductsRequest
    private var timer: Timer?

    override public init() {
        precondition(!Self.isInitialized, "IAPService must only initialized once.")
        Self.isInitialized = true

        let productIdentifiers = SubscriptionType.allCases.map(\.rawValue)
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))

        super.init()

        #if DEBUG
        appUsagePermitted = true
        #else
        InAppReceipt.refresh { [weak self] error in
            if let error = error {
                Self.log.error("Failed to refresh receipt.", metadata: ["error": "\(error)"])
                if Self.shouldHandle(error) {
                    NotificationCenter.default.postAlert(error)
                }
            } else {
                self?.validateReceipt()
            }
        }

        paymentQueue.add(self)

        productsRequest.delegate = self
        productsRequest.start()

        // validate the receipt at least once every hour in case the user has cancelled the subscription
        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.validateReceipt()
        }
        #endif
    }

    /// Create and add a payment request to the payment queue.
    public func buy(subscription: SubscriptionType) throws {
        log.debug("buy \(subscription)")
        guard let product = products.first(where: { $0.productIdentifier == subscription.rawValue }) else { throw IAPError.purchaseFailedProductNotFound }
        let payment = SKMutablePayment(product: product)
        paymentQueue.add(payment)
    }

    /// Restores all previously completed purchases.
    public func restorePurchases() {
        log.debug("restore")
        // state changes will be handled at: paymentQueueRestoreCompletedTransactionsFinished
        paymentQueue.restoreCompletedTransactions()
    }

    private func validateReceipt() {
        do {
            // Initialize receipt
            let receipt = try InAppReceipt.localReceipt()

            // Verify hash, bundleID, version and signiture
            try receipt.verify()

            // Retrieve Active Auto Renewable Subscription's Purchases for Product Name and Specific Date
            let productIdentifiers = SubscriptionType.allCases.map(\.rawValue)
            let hasActiveSubscription = receipt.activeAutoRenewableSubscriptionPurchases
                .contains { productIdentifiers.contains($0.productIdentifier) }

            appUsagePermitted = hasActiveSubscription
        } catch {
            appUsagePermitted = false
            log.errorAndAssert("Failed to validate receaipt", metadata: ["error": "\(error)"])
            if Self.shouldHandle(error) {
                NotificationCenter.default.postAlert(error)
            }
        }
    }
}

extension IAPService: IAPServiceAPI {
    public var productsPublisher: AnyPublisher<Set<SKProduct>, Never> {
        $products.eraseToAnyPublisher()
    }

    public var appUsagePermittedPublisher: AnyPublisher<Bool, Never> {
        $appUsagePermitted.eraseToAnyPublisher()
    }
}

extension IAPService: SKPaymentTransactionObserver {
    /// Called when there are transactions in the payment queue.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        log.info("updatedTransactions \(transactions)")
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                log.debug("Payment completed.")
                paymentQueue.finishTransaction(transaction)
            case .failed:
                log.debug("Payment failed.")
            case .restored:
                log.debug("Payment restored.")
                queue.finishTransaction(transaction)
            case .deferred:
                log.debug("Payment deferred.")
            case .purchasing:
                log.debug("In purchasing process.")
                @unknown default:
                    preconditionFailure("Unkown transaction state: \(transaction.transactionState)")
            }
        }
    }

    /// Logs all transactions that have been removed from the payment queue.
    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        log.debug("removedTransactions \(transactions)")
        validateReceipt()
    }

    /// Called when an error occur while restoring purchases. Notify the user about the error.
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        log.error("restoreCompletedTransactionsFailedWithError", metadata: ["error": "\(error)"])
        guard (error as? SKError)?.code != .paymentCancelled,
              Self.shouldHandle(error) else { return }
        NotificationCenter.default.postAlert(error)
    }

    /// Tells the observer that a user initiated an in-app purchase from the App Store.
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        log.info("shouldAddStorePayment was called.")
        return true
    }

    /// Called when all restorable transactions have been processed by the payment queue.
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        log.debug("paymentQueueRestoreCompletedTransactionsFinished")
        validateReceipt()

        DispatchQueue.main.async {
            if self.appUsagePermitted {
                NotificationCenter.default.createAndPost(title: "Subscription",
                                                         message: "✅ An active subscription was successfully restored.",
                                                         primaryButtonTitle: "OK")
            } else {
                NotificationCenter.default.createAndPost(title: "Subscription",
                                                         message: "❌ No active subscription could be restored.\nPlease contact us if this is an error:\nMore > Support",
                                                         primaryButtonTitle: "OK")
            }
        }
    }

    public func paymentQueue(_ queue: SKPaymentQueue, didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        log.info("didRevokeEntitlementsForProductIdentifiers \(productIdentifiers)")
        validateReceipt()
    }

    // MARK: - Helper Functions

    private static func shouldHandle(_ error: Error) -> Bool {
        // This is a hacky workaround for fixing:
        // * https://developer.apple.com/forums/thread/661351
        // * https://openradar.appspot.com/FB8907873
        !"\(error)".lowercased().contains("unhandled exception")
    }
}

extension IAPService: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = Set(response.products)
    }
}
