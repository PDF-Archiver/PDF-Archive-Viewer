//
//  ScanTabViewController.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 31.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import SwiftUI
import SwiftUIX

public struct ScanTabView: View {
    @ObservedObject var viewModel: ScanTabViewModel
    @State private var opacity = 0.0

    public init(viewModel: ScanTabViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            Spacer()
            staticInfo
            Spacer()
            VStack(alignment: .leading) {
                ProgressView(viewModel.progressLabel, value: viewModel.progressValue)
                    .opacity(viewModel.progressValue > 0.0 ? 1 : 0)
                scanButton
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(EdgeInsets(top: 32.0, leading: 16.0, bottom: 32.0, trailing: 16.0))
    }

    private var staticInfo: some View {
        VStack(alignment: .leading) {
            Image("Logo")
                .resizable()
                .frame(width: 100, height: 100, alignment: .leading)
                .padding()
            Text("Welcome to")
                .font(.largeTitle)
                .fontWeight(.heavy)
            Text("PDF Archiver")
                .foregroundColor(Color(.paDarkRed))
                .font(.largeTitle)
                .fontWeight(.heavy)
            Text("Scan your documents, tag them and find them sorted in your iCloud Drive.")
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
        }
        .padding(16.0)
        .foregroundColor(Color(.paDarkGray))
        .opacity(opacity)
        .onAppear {
            withAnimation {
                opacity = 1.0
            }
        }
    }

    var scanButton: some View {
        HStack {
            Spacer()
            Button(action: {
                self.viewModel.startScanning()
            }, label: {
                Text("Scan")
            }).buttonStyle(FilledButtonStyle())
            .keyboardShortcut("s")
            Spacer()
        }
        .padding()
    }
}

#if DEBUG
import StoreKit
struct ScanTabView_Previews: PreviewProvider {
    private class ImageConverter: ImageConverterAPI {
        var totalDocumentCount = Atomic<Int>(5)
        func handle(_ url: URL) throws {}
        func startProcessing() throws {}
        func stopProcessing() {}
        func getOperationCount() -> Int { 4 }
    }

    private class IAPService: IAPServiceAPI {
        weak var delegate: IAPServiceDelegate?
        var products = Set<SKProduct>()
        var requestsRunning: Int = 5

        func appUsagePermitted() -> Bool {
            true
        }
        func buyProduct(_ product: SKProduct) {}
        func buyProduct(_ productIdentifier: String) {}
        func restorePurchases() {}
    }

    static var previews: some View {
        ScanTabView(viewModel: ScanTabViewModel(imageConverter: ImageConverter(), iapService: IAPService(), documentsFinishedHandler: { print("Scan completed!") }))
            .frame(maxWidth: .infinity)
            .padding()
    }
}
#endif
