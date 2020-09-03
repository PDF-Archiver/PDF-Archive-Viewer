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

struct MoreTabView: View {

    @ObservedObject var viewModel: MoreTabViewModel
    private static let appVersion = AppEnvironment.getFullVersion()

    var body: some View {
        HStack {
            if UIDevice.current.userInterfaceIdiom != .phone {
                Spacer()
            }
            NavigationView {
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
                .navigationBarTitleView(title)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .frame(maxWidth: 500)
            if UIDevice.current.userInterfaceIdiom != .phone {
                Spacer()
            }
        }
        .backgroundFill(.systemGroupedBackground)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: viewModel.updateSubscription)
    }

    private var title: some View {
        Text("Preferences & More")
            .font(.largeTitle)
            .fontWeight(.bold)
            .background(Color(.systemGroupedBackground))
            .maxWidth(.infinity)
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
            Link("Terms of Use & Privacy Policy", destination: viewModel.privacyPolicyUrl)
            Link("Imprint", destination: viewModel.imprintUrl)
            DetailRowView(name: "Support  🚑") {
                self.viewModel.showSupport()
            }
        }
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
