//
//  ArchiveView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 27.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import SwiftUI
import SwiftUIX

struct ArchiveView: View {
    @ObservedObject var viewModel: ArchiveViewModel

    var body: some View {
        NavigationView {
            if viewModel.showLoadingView {
                LoadingView()
            } else {
                VStack {
                    searchView
                    documentsView
                    .resignKeyboardOnDragGesture()
                }
                .navigationBarTitle(Text("Documents"))
            }
            emptyView
        }
        // On iPad: force double column view
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }

    var searchView: some View {
        SearchField(searchText: $viewModel.searchText,
                    scopes: $viewModel.years,
                    selectionIndex: $viewModel.scopeSelecton,
                    placeholder: "Search")
            .padding(EdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 8.0))
    }

    var documentsView: some View {
        List {
            ForEach(viewModel.documents) { document in
                if document.downloadStatus == .local {
                    NavigationLink(destination: ArchiveViewModel.createDetail(with: document)) {
                        DocumentView(viewModel: document, showTagStatus: false)
                    }
                } else {
                    DocumentView(viewModel: document, showTagStatus: false)
                        .onTapGesture {
                            self.viewModel.tapped(document)
                        }
                }
            }.onDelete(perform: viewModel.delete(at:))
        }
    }

    var emptyView: some View {
        let name: LocalizedStringKey
        if viewModel.showLoadingView {
            name = ""
        } else if viewModel.documents.isEmpty {
            name = "No iCloud Drive documents found.\nPlease scan and tag documents first or change filter."
        } else {
            name = "Select a document."
        }
        return PlaceholderView(name: name)
    }
}

struct ArchiveView_Previews: PreviewProvider {

    static let viewModel = ArchiveViewModel()

    static var previews: some View {
        ArchiveView(viewModel: viewModel)
    }
}
