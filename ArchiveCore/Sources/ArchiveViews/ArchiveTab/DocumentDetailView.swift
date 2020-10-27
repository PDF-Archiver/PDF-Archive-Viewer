//
//  DocumentDetailView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 30.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import SwiftUIX

struct DocumentDetailView: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    var body: some View {
        VStack {
            DocumentView(viewModel: viewModel.document, showTagStatus: false)
                .padding()
            PDFCustomView(viewModel.pdfDocument)
        }
        .navigationBarTitle(Text(""), displayMode: .inline)
        .navigationBarItems(trailing: shareNavigationButton)
        .onAppear(perform: viewModel.viewAppeared)
        .sheet(isPresented: $viewModel.showActivityView) {
            AppActivityView(activityItems: self.viewModel.activityItems)
        }
    }

    var shareNavigationButton: some View {
        Button(action: {
            self.viewModel.showActivityView = true
        }, label: {
            Image(systemName: "square.and.arrow.up")
        })
    }
}
