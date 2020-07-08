//
//  Stack.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 22.02.20.
//  Copyright © 2020 Julian Kahnert. All rights reserved.
//

import SwiftUI

struct Stack<Content: View>: View {

    var spacing: CGFloat
    var content: Content

    init(spacing: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width * 1.3 < geometry.size.height {
                VStack(alignment: .center, spacing: spacing) {
                    content
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .center, spacing: spacing) {
                    content
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct Stack_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Stack {
                Text("Text 1")
                    .padding(.all, 20)
                    .backgroundColor(.green)
                Text("Text 2")
                    .padding(.all, 20)
                    .backgroundColor(.blue)
            }
            .previewLayout(.fixed(width: 800.0, height: 200.0))
            Stack {
                Text("Text 1")
                    .padding(.all, 20)
                    .backgroundColor(.green)
                Text("Text 2")
                    .padding(.all, 20)
                    .backgroundColor(.blue)
            }
            .previewLayout(.fixed(width: 200.0, height: 800.0))
        }
    }
}
