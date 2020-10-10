//
//  IAPServiceAPI.swift
//  
//
//  Created by Julian Kahnert on 11.10.20.
//

import StoreKit

public protocol IAPServiceAPI: class {
    var delegate: IAPServiceDelegate? { get set }
    var products: Set<SKProduct> { get }
    var requestsRunning: Int { get }
    
    func appUsagePermitted(appStart: Bool) -> Bool
    func buyProduct(_ product: SKProduct)
    func buyProduct(_ productIdentifier: String)
    func restorePurchases()
}
