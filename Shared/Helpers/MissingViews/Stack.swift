//
//  Stack.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 22.02.20.
//  Copyright © 2020 Julian Kahnert. All rights reserved.
//

import SwiftUI

struct Stack<Content: View>: View {

    var content: Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry -> AnyView in
            if UIDevice.current.userInterfaceIdiom == .phone || geometry.size.width * 1.5 < geometry.size.height {
                return AnyView(
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .center, spacing: 16) {
                            self.content
                        }
                    }
                )
            } else {
                return AnyView(
                    HStack(alignment: .center, spacing: 16) {
                        self.content
                    }
                )
            }
        }
    }
}
