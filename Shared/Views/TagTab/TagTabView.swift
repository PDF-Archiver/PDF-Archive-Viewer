//
//  TagTabView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 02.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import SwiftUI

struct TagTabView: View {

    @Namespace var namespace

    @ObservedObject var viewModel: TagTabViewModel

    // trigger a reload of the view, when the device rotation changes
    @EnvironmentObject var orientationInfo: OrientationInfo

    var body: some View {
        NavigationView {
            if viewModel.showLoadingView {
                LoadingView()
            } else if viewModel.currentDocument != nil {
                GeometryReader { geometry in
                    Stack(spacing: 8) {
                        if shouldShowDocumentList(width: geometry.size.width) {
                            documentsList
                                .frame(maxWidth: size(of: .documentList, width: geometry.size.width))
                        }
                        pdfView
                            .frame(maxWidth: size(of: .pdf, width: geometry.size.width), minHeight: 175.0, maxHeight: .infinity, alignment: .center)
                        documentInformation
                            .frame(maxWidth: size(of: .documentInformation, width: geometry.size.width))
//                            .keyboardPadding()
                    }
                }
                .navigationBarTitle(Text("Document"), displayMode: .inline)
                .navigationBarItems(leading: deleteNavBarView, trailing: saveNavBarView)
            } else {
                PlaceholderView(name: "No iCloud Drive documents found. Please scan and tag documents first.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onTapGesture {
            self.endEditing(true)
        }
    }

    private var deleteNavBarView: some View {
        Button(action: {
            self.viewModel.deleteDocument()
        }, label: {
            VStack {
                Image(systemName: "trash")
                Text("Delete")
                    .font(.system(size: 11.0))
            }
        })
    }

    private var saveNavBarView: some View {
        Button(action: {
            self.viewModel.saveDocument()
        }, label: {
            VStack {
                Image(systemName: "square.and.arrow.down")
                Text("Add")
                    .font(.system(size: 11.0))
            }
        })
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

    // MARK: - Layout Helpers

    private func shouldShowDocumentList(width: CGFloat) -> Bool {
        guard width > 900.0 else { return false }
        let screenSize = UIScreen.main.bounds.size
        return UIDevice.current.userInterfaceIdiom != .phone && screenSize.height < screenSize.width
    }

    private enum Element {
        case documentList, pdf, documentInformation
    }

    private func size(of element: Element, width: CGFloat) -> CGFloat {
        switch element {
        case .documentList:
            return width / 6 * 1
        case .pdf:
            return .infinity
        case .documentInformation:
            if UIDevice.current.userInterfaceIdiom != .phone {
                return max(width / 6 * 2, 320)
            } else {
                return .infinity
            }
        }
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
//            .previewDevice("iPhone 11")
    }
}
#endif
