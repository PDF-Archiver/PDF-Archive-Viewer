//
//  DocumentDetailViewModel.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 30.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Foundation
import PDFKit

class DocumentDetailViewModel: ObservableObject {
    let document: Document
    @Published var pdfDocument: PDFDocument?
    @Published var showActivityView: Bool = false
    var activityItems: [Any] {
        [document.path]
    }
    private let selectionFeedback = UISelectionFeedbackGenerator()

    init(_ document: Document) {
        self.document = document
        pdfDocument = PDFDocument(url: document.path)
    }

    func viewAppeared() {
        selectionFeedback.prepare()
        selectionFeedback.selectionChanged()
    }
}
