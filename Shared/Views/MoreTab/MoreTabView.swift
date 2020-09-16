//
//  MoreTabView.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 13.11.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import LogModel
import MessageUI
import SwiftUI
import Parma

struct MoreTabView: View {

    @ObservedObject var viewModel: MoreTabViewModel
    private static let appVersion = AppEnvironment.getFullVersion()

    var body: some View {
        Form {
            preferences
            subscription
            moreInformation
        }
        .listStyle(GroupedListStyle())
        .foregroundColor(.primary)
        .sheet(isPresented: $viewModel.isShowingMailView) {
            SupportMailView(subject: MoreTabViewModel.mailSubject,
                            recipients: MoreTabViewModel.mailRecipients,
                            result: self.$viewModel.result)
        }
        .navigationTitle("Preferences & More")
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: viewModel.updateSubscription)
    }

    private var preferences: some View {
        Section(header: Text("🛠 Preferences")) {
            Picker(selection: $viewModel.selectedQualityIndex, label: Text("PDF Quality")) {
                ForEach(0..<viewModel.qualities.count, id: \.self) {
                    Text(self.viewModel.qualities[$0])
                }
            }
            DetailRowView(name: "Show Intro") {
                self.viewModel.showIntro()
            }
            DetailRowView(name: "Show Permissions") {
                self.viewModel.showPermissions()
            }
            DetailRowView(name: "Reset App Preferences") {
                self.viewModel.resetApp()
            }
        }
    }

    private var subscription: some View {
        Section(header: Text("🧾 Subscription")) {
            HStack {
                Text("Status:")
                Text(viewModel.subscriptionStatus)
            }

            DetailRowView(name: "Activate Subscription") {
                NotificationCenter.default.post(.showSubscriptionView)
            }
            Link("Manage Subscription", destination: viewModel.manageSubscriptionUrl)
        }
    }

    private var moreInformation: some View {
        Section(header: Text("⁉️ More Information"), footer: Text("Version \(MoreTabView.appVersion)")) {
            NavigationLink(destination: AboutMeView()) {
                Text("About  👤")
            }
            Link("PDF Archiver (macOS)  🖥", destination: viewModel.macOSAppUrl)
            NavigationLink(destination: markdownView(for: "Privacy")) {
                Text("Terms of Use & Privacy Policy")
            }
            NavigationLink(destination: markdownView(for: "Imprint")) {
                Text("Imprint")
            }
            DetailRowView(name: "Support  🚑") {
                self.viewModel.showSupport()
            }
        }
    }

    private func markdownView(for key: String) -> some View {
        guard let url = Bundle.main.url(forResource: key, withExtension: "md"),
              let markdown = try? String(contentsOf: url) else { preconditionFailure("Could not fetch file \(key)") }
        return ScrollView {
            Parma(markdown)
        }
        .navigationTitle(LocalizedStringKey(key))
    }
}

struct MoreTabView_Previews: PreviewProvider {
    @State static var viewModel = MoreTabViewModel()
    static var previews: some View {
        Group {
            MoreTabView(viewModel: viewModel)
                .preferredColorScheme(.dark)
                .padding()
        }
    }
}
