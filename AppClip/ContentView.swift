//
//  ContentView.swift
//  AppClip
//
//  Created by Julian Kahnert on 10.10.20.
//

import ArchiveViews
import ArchiveBackend
import SwiftUI

struct ContentView: View {
    static let imageConverter = ImageConverter(getDocumentDestination: { PathManager.tempPdfURL },
                                               shouldStartBackgroundTask: true)

    @StateObject var viewModel = ScanTabViewModel(imageConverter: imageConverter, iapService: AppClipIAPService())
    var body: some View {
        ScanTabView(viewModel: viewModel)
    }
}

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
