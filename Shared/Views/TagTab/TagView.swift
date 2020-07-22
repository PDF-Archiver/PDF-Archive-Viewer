//
//  TagView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 10.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import SwiftUI

struct TagView: View, Identifiable {

    var id: String {
        tagName
    }

    @Namespace var namespace

    let tagViewNamespace: Namespace.ID
    let tagName: String
    let isEditable: Bool
    let tapHandler: ((String) -> Void)?

    var body: some View {
        Button(action: {
            self.tapHandler?(self.tagName)
        }, label: {
            self.tag
        })
        .matchedGeometryEffect(id: tagName, in: namespace)
    }

    private var tag: some View {
        HStack {
            Image(systemName: "tag")
            Text(self.tagName)
                .lineLimit(1)
            if self.isEditable {
                Image(systemName: "xmark.circle.fill")
            }
        }
        .padding(EdgeInsets(top: 2.0, leading: 5.0, bottom: 2.0, trailing: 5.0))
        .foregroundColor(.white)
        // TODO: fix this
//        .background(Color(.paLightRed))
        .background(Color.red)
        .cornerRadius(8.0)
        .transition(.opacity)
        .animation(.spring())
    }
}

struct TagView_Previews: PreviewProvider {
    struct TagTempView: View {
        @Namespace var namespace
        var tagName = "tag1"
        var isEditable = true
        var tapHandler: ((String) -> Void) = { tag in
            print("Tapped on tag: \(tag)")
        }

        var body: some View {
            TagView(tagViewNamespace: namespace,
                    tagName: tagName,
                    isEditable: isEditable,
                    tapHandler: tapHandler)
        }
    }

    static var previews: some View {
        TagTempView()
            .previewLayout(.sizeThatFits)
    }
}
