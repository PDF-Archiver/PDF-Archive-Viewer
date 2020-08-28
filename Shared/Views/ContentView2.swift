//
//  ContentView2.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 28.08.20.
//

import Combine
import SwiftUI

struct Tab: Identifiable, Hashable, Equatable {
    enum TabType: Int, Hashable {
        case scan = 0
        case tag, archive, more
    }

    var id: String { name }
    let name: String
    let iconName: String
    let type: TabType
}

struct Category: Identifiable {
    var id: String { name }
    let name: String
    let items: [CategoryItem]
}

struct CategoryItem: Identifiable, Hashable {
    enum CategoryItemType {
        case archive, tags
    }

    let id = UUID()
    let type: CategoryItemType
    let name: String
}

//struct ContentView2: View {
//
//
//
//    let model = Model()
//    @State var selection: Tab? = Model.tabs.first
//
//    var body: some View {
//        #if os(macOS)
//        sidebar
//        #else
//        if horizontalSizeClass == .compact {
//            tabbar
//        } else {
//            sidebar
//        }
//        #endif
//    }
//
//
//}
//
//struct ContentView2_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView2()
//    }
//}
