//
//  OnboardingScreens.swift
//  Onboarding
//
//  Created by Stewart Lynch on 2020-06-27.
//

import SwiftUI

struct OnboardingScreens: View {
    @State private var index = 0
    @Binding var isPresenting: Bool
    var onboardSet: OnboardSet
    var body: some View {
        OBCardView(isShowing: $isPresenting, showNextHandler: showNextHandler, card: onboardSet.cards[index], width: onboardSet.width, height: onboardSet.height)
    }

    private func showNextHandler() {
        let nextIndex = index + 1
        if nextIndex < onboardSet.cards.count {
            index = nextIndex
        } else {
            isPresenting = false
        }
    }
}

struct OnboardingScreens_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingScreens(isPresenting: .constant(true), onboardSet: OnboardSet.previewSet())
    }
}
