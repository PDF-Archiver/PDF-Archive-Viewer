//
//  DocumentInformationForm.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 03.07.20.
//

import SwiftUI

struct DocumentInformationForm: View {

    @Binding var date: Date
    @Binding var specification: String
    @Binding var tags: [String]

    @Binding var tagInput: String
    @Binding var suggestedTags: [String]
    @Binding var inputAccessoryViewSuggestions: [String]

    @Namespace private var namespace

    var body: some View {
        Form {
//        VStack(alignment: .leading, spacing: 16.0) {
//            datePicker
            DatePicker("Date", selection: $date, displayedComponents: .date)
            TextField("Description", text: $specification)
                .modifier(ClearButton(text: $specification))
            documentTagsView
            suggestedTagsView
            Spacer()
        }
    }

    private func documentTagTapped(_ tag: String) {
        print("hello2")
    }

    private func saveTag(_ tag: String) {
        print("hello")
    }

    private func suggestedTagTapped(_ tag: String) {
        print("hello3")
    }

    private var documentTagsView: some View {
        VStack(alignment: .leading) {
            Text("Document Tags")
                .font(.caption)
            TagListView(tagViewNamespace: namespace,
                        tags: $tags,
                        isEditable: true,
                        isMultiLine: true,
                        tapHandler: documentTagTapped(_:))
                .font(.body)
            CustomTextField(text: $tagInput,
                            placeholder: "Enter Tag",
                            onCommit: saveTag,
                            isFirstResponder: false,
                            suggestions: self.inputAccessoryViewSuggestions)
                .frame(maxHeight: 22)
                .padding(EdgeInsets(top: 4.0, leading: 0.0, bottom: 4.0, trailing: 0.0))
        }
    }

    private var suggestedTagsView: some View {
        VStack(alignment: .leading) {
            Text("Suggested Tags")
                .font(.caption)
            TagListView(tagViewNamespace: namespace,
                        tags: $suggestedTags,
                        isEditable: false,
                        isMultiLine: true,
                        tapHandler: suggestedTagTapped(_:))
                .font(.body)
        }
    }
}

struct DocumentInformationForm_Previews: PreviewProvider {
    static var previews: some View {
        DocumentInformationForm(date: .constant(Date()),
                                specification: .constant("Blue Pullover"),
                                tags: .constant(["bill", "clothes"]),
                                tagInput: .constant("te"),
                                suggestedTags: .constant(["tag1", "tag2", "tag3"]),
                                inputAccessoryViewSuggestions: .constant([]))
    }
}
