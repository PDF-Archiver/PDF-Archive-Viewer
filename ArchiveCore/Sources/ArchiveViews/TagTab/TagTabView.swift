//
//  TagTabView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 02.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import SwiftUI

struct TagTabView: View {

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @ObservedObject var viewModel: TagTabViewModel

    // trigger a reload of the view, when the device rotation changes
    @EnvironmentObject var orientationInfo: OrientationInfo

    var body: some View {
        if viewModel.showLoadingView {
            LoadingView()
                .navigationBarHidden(true)
                .emittingError(viewModel.error)
        } else if viewModel.currentDocument != nil {
            Stack(spacing: 8) {
                #if os(iOS)
                if horizontalSizeClass != .compact {
                    documentsList
                }
                #else
                documentsList
                #endif
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        pdfView
                            .frame(height: geometry.size.height * 0.6)
                        documentInformation
                            .frame(height: geometry.size.height * 0.4)
                    }
                }
            }
            .navigationBarHidden(false)
            .navigationBarTitle(Text("Document"), displayMode: .inline)
            .navigationBarItems(leading: deleteNavBarView, trailing: saveNavBarView)
            .emittingError(viewModel.error)
        } else {
            PlaceholderView(name: "No iCloud Drive documents found. Please scan and tag documents first.")
                .navigationBarHidden(true)
                .emittingError(viewModel.error)
        }
    }

    private var deleteNavBarView: some View {
        Button(action: {
            self.viewModel.deleteDocument()
        }, label: {
            VStack {
                Image(systemName: "trash")
                Text("Delete")
                    .font(.caption)
            }
            .padding(.horizontal, 24)
        })
        .disabled(viewModel.currentDocument == nil)
    }

    private var saveNavBarView: some View {
        Button(action: {
            self.viewModel.saveDocument()
        }, label: {
            VStack {
                Image(systemName: "square.and.arrow.down")
                Text("Add")
                    .font(.caption)
            }
            .padding(.horizontal, 24)
        })
        .disabled(viewModel.currentDocument == nil)
    }

    // MARK: Component Groups

    private var documentsList: some View {
        VStack {
            Text("Tagged: \(viewModel.taggedUntaggedDocuments)")
                .font(Font.headline)
                .padding()
            List {
                ForEach(viewModel.documents) { document in
                    HStack {
                        Circle()
                            .fill(Color.systemBlue)
                            .frame(width: 8, height: 8)
                            .opacity(document == self.viewModel.currentDocument ? 1 : 0)
                        DocumentView(viewModel: document, showTagStatus: true)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                       self.viewModel.currentDocument = document
                    }
                }
            }
        }
        .frame(maxWidth: 300)
    }

    private var pdfView: some View {
        PDFCustomView(self.viewModel.pdfDocument)
    }

    private var documentInformation: some View {
        DocumentInformationForm(date: $viewModel.date,
                                specification: $viewModel.specification,
                                tags: $viewModel.documentTags,
                                tagInput: $viewModel.documentTagInput,
                                suggestedTags: $viewModel.suggestedTags,
                                inputAccessoryViewSuggestions: $viewModel.inputAccessoryViewSuggestions)
    }
}

#if DEBUG
struct TagTabView_Previews: PreviewProvider {
    static var viewModel: TagTabViewModel = {
        let model = TagTabViewModel()
        model.showLoadingView = false
        model.date = Date()
        model.documents = [
            Document.create(),
            Document.create(),
            Document.create()
        ]
        model.documentTags = ["bill", "letter"]
        model.suggestedTags = ["tag1", "tag2", "tag3"]
        model.currentDocument = Document.create()
        return model
    }()

    static var previews: some View {
        TagTabView(viewModel: viewModel)
            .makeForPreviewProvider()
    }
}
#endif
