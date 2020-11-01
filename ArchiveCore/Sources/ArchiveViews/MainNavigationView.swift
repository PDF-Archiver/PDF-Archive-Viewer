//
//  MainNavigationView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 30.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Combine
import SwiftUI

public struct MainNavigationView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @StateObject public var viewModel = MainNavigationViewModel()

    public init() { }

    public var body: some View {
        ZStack {
            #if os(macOS)
            sidebar
            #else
            if horizontalSizeClass == .compact {
                tabbar
            } else {
                sidebar
            }
            #endif
            if viewModel.scanViewModel.showDocumentScan {
                documentCameraView
            }
        }
        .intro(when: $viewModel.showTutorial)
        .sheet(isPresented: $viewModel.showSubscriptionView,
               onDismiss: viewModel.handleIAPViewDismiss) {
            IAPView(viewModel: self.viewModel.iapViewModel)
        }
        .emittingError(viewModel.error)
    }

    private var sidebar: some View {
        NavigationView {
            List {
                ForEach(Tab.allCases) { tab in
                    NavigationLink(destination: viewModel.view(for: tab), tag: tab, selection: $viewModel.currentOptionalTab) {
                        Label {
                            Text(LocalizedStringKey(tab.name))
                        } icon: {
                            Image(systemName: tab.iconName)
                                .accentColor(Color(.paDarkRed))
                        }
                    }
                }

                Section(header: Text("Archive")) {
                    ForEach(viewModel.archiveCategories) { category in
                        Button {
                            viewModel.selectedArchive(category)
                        } label: {
                            Label(category, systemImage: "folder")
                        }
                    }
                    .accentColor(.systemGray)
                }

                Section(header: Text("Tags")) {
                    ForEach(viewModel.tagCategories) { category in
                        Button {
                            viewModel.selectedTag(category)
                        } label: {
                            Label(category, systemImage: "tag")
                        }
                    }
                    .accentColor(.blue)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Documents")

            Text("Select a tab")

            // Would be great to show a thrid column in .archive case, but this is currently not possible:
            // https://github.com/JulianKahnert/NavigationExample
//            if viewModel.currentTab == .archive {
//                if let selectedDocument = viewModel.archiveViewModel.selectedDocument {
//                    ArchiveViewModel.createDetail(with: selectedDocument)
//                } else {
//                    Text("Select a tab")
//                }
//            }
        }
    }

    private var tabbar: some View {
        TabView(selection: $viewModel.currentTab) {
            ForEach(Tab.allCases) { tab in
                viewModel.view(for: tab)
                    .wrapNavigationView(when: tab != .scan)
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tabItem {
                        Label(tab.name, systemImage: tab.iconName)
                    }
                    .tag(tab)
            }
        }
    }

    private var documentCameraView: some View {
        DocumentCameraView(
            isShown: $viewModel.scanViewModel.showDocumentScan,
            imageHandler: viewModel.scanViewModel.process)
            .edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
    }
}

//struct MainNavigationView_Previews: PreviewProvider {
//    @State static var viewModel = MainNavigationViewModel()
//    static var previews: some View {
//        MainNavigationView(viewModel: viewModel)
//    }
//}

fileprivate extension View {

    @ViewBuilder
    func intro(when value: Binding<Bool>) -> some View {
        if value.wrappedValue {
            ZStack {
                self
                    .redacted(reason: .placeholder)
                    .blur(radius: 15)

                OnboardingView(isPresenting: value)
            }
        } else {
            self
        }
    }
}
