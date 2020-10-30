//
//  PDFSharingView.swift
//  AppClip
//
//  Created by Julian Kahnert on 23.10.20.
//

import ArchiveViews
import PDFKit
import SwiftUI
import SwiftUIX

struct PDFSharingView: View {
    var viewModel: PDFSharingViewModel

    var body: some View {
        ZStack {
            Color.systemBackground
            documentView
        }
        .onChange(of: viewModel.pdfDocument, perform: { _ in
            print("ViewModel has changed.")
        })
    }

    private var documentView: some View {
        VStack(spacing: 16) {
            header

            Text("Processing Completed! 📄")
                .font(.body)
                .foregroundColor(Color(.paDarkGray))

            if let pdfDocument = viewModel.pdfDocument {
                PDFCustomView(pdfDocument)
                    .padding()
                    .frame(maxWidth: 500, maxHeight: 500)
                    .shadow(radius: 8)
                    .padding()
            }

            HStack {
                Button(action: {
                    viewModel.shareDocument()
                }, label: {
                    Label("Share" as LocalizedStringKey, systemImage: .squareAndArrowUp)
                })
                .buttonStyle(FilledButtonStyle(foregroundColor: Color(.paWhite), backgroundColor: Color(.paDarkGray)))

                Button(action: {
                    viewModel.delete()
                }, label: {
                    Text("Delete")
                })
                .buttonStyle(FilledButtonStyle(foregroundColor: Color(.paDarkRed), backgroundColor: Color(.systemBackground)))
            }
            .padding()

            Spacer()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image("Logo")
                .resizable()
                .frame(width: 75, height: 75, alignment: .leading)
            Text("PDF Archiver")
                .foregroundColor(Color(.paDarkRed))
                .font(.largeTitle)
                .fontWeight(.heavy)
        }
    }
}

#if DEBUG
struct PDFSharingView_Previews: PreviewProvider {
    static var previews: some View {
        PDFSharingView(viewModel: PDFSharingViewModel())
            .previewLayout(.sizeThatFits)
            .makeForPreviewProvider()
    }
}
#endif
