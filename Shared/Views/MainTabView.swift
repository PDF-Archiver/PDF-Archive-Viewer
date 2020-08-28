//
//  MainTabView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 30.10.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import Combine
import SwiftUI

struct MainTabView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @StateObject var viewModel = MainTabViewModel()

    var body: some View {
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
            if viewModel.showSubscriptionView {
                IAPView(viewModel: self.viewModel.iapViewModel)
            }
            if viewModel.showTutorial {
                introView
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(viewModel: viewModel.alertViewModel)
        }
    }

    private var sidebar: some View {
        NavigationView {
            List {
                ForEach(viewModel.tabs) { tab in
                    NavigationLink(destination: viewModel.view(for: tab.type), tag: tab.type, selection: $viewModel.currentTab) {
                        Label(tab.name, systemImage: tab.iconName)
                    }
                }

                ForEach(viewModel.categories) { canvas in
                    Section(header: Text(canvas.name)) {
                        ForEach(canvas.items) { item in
                            Button(action: {
                                // TODO: handle action
                                print("Pressed item \(item)")
                            }) {
                                switch item.type {
                                    case .archive:
                                        Label(item.name, systemImage: "folder.fill")
                                    case .tags:
                                        Label(item.name, systemImage: "tag.fill")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Documents")

            // TODO: start with scan tab
            Text("Select a tab")

            // TODO: handle updates when document selection changes
            if let selectedDocument = viewModel.archiveViewModel.selectedDocument {
                ArchiveViewModel.createDetail(with: selectedDocument)
            }
        }
    }

    private var tabbar: some View {
        TabView(selection: $viewModel.currentTab) {
            ForEach(viewModel.tabs) { tab in
                viewModel.view(for: tab.type)
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

    private var introView: some View {
        IntroView()
            .edgesIgnoringSafeArea(.all)
            .statusBar(hidden: true)
    }
}

//struct MainTabView_Previews: PreviewProvider {
//    @State static var viewModel = MainTabViewModel()
//    static var previews: some View {
//        MainTabView(viewModel: viewModel)
//    }
//}
