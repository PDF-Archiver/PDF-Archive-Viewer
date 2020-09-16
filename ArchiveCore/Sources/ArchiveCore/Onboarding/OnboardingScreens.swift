//
//  OnboardingScreens.swift
//  Onboarding
//
//  Created by Stewart Lynch on 2020-06-27.
//

import SwiftUI

struct OnboardingScreens: View {
    @Binding var isPresenting: Bool
    var onboardSet: OnboardSet
    var body: some View {
        VStack {
            TabView {
                ForEach(onboardSet.cards) { item in
                    OBCardView(isShowing: $isPresenting, card: item, width: onboardSet.width, height: onboardSet.height)
                }
            }.frame(height: onboardSet.height + 120)
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            Spacer()
        }
    }
}

struct OnboardingScreens_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreens(isPresenting: .constant(true), onboardSet: OnboardSet.previewSet())
    }
}
