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
    @State var viewModel = PDFSharingViewModel()
    
    var body: some View {
        ZStack {
            Color.systemBackground
            documentView
            
            if let sharingUrl = viewModel.sharingUrl {
                ActivityView(activityItems: [sharingUrl])
            }
        }
        .hidden(viewModel.pdfDocument == nil)
    }
    
    private var documentView: some View {
        VStack {
            
            
            if let pdfDocument = viewModel.pdfDocument {
                PDFCustomView(pdfDocument)
                    .padding()
                    .frame(maxWidth: 500, maxHeight: 500)
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    viewModel.shareDocument()
                }, label: {
                    Label("Share", systemImage: .squareAndArrowUp)
                }).buttonStyle(FilledButtonStyle())
                
                Button(action: {
                    viewModel.cancel()
                }, label: {
                    Text("Cancel")
                }).buttonStyle(FilledButtonStyle())
            }
            
            Spacer()
        }
    }
}

struct PDFSharingView_Previews: PreviewProvider {
    static var previews: some View {
        PDFSharingView()
    }
}
