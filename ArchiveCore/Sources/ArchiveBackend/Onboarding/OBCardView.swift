//
//  OBCardView.swift
//  Onboarding
//
//  Created by Stewart Lynch on 2020-06-27.
//

import SwiftUI

struct OBCardView: View {
    @Binding var isShowing: Bool
    let showNextHandler: () -> Void
    let card: OnboardCard
    let width: CGFloat
    let height: CGFloat
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Spacer()
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.title)
                }
            }
            Spacer()
            Image(card.image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 100, maxHeight: 100)
            Spacer()
            Text(card.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.accentColor)
                .multilineTextAlignment(.center)
            Text(card.text)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.9)
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        showNextHandler()
                    }
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.largeTitle)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical)
        .frame(width: width, height: height)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(radius: 10))
    }
}

struct OBCardView_Previews: PreviewProvider {
    static let onboardSet = OnboardSet.previewSet()
    static var previews: some View {
        Group {
            OBCardView(isShowing: .constant(true), showNextHandler: {}, card: onboardSet.cards[0], width: 350, height: 350)
                .previewLayout(.sizeThatFits)
            OBCardView(isShowing: .constant(true), showNextHandler: {}, card: onboardSet.cards[3], width: 400, height: 500)
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
        }
    }
}
