//
//  StorageSelectionView.swift
//  
//
//  Created by Julian Kahnert on 18.11.20.
//

import SwiftUI

struct StorageSelectionView: View {

    @Binding var selection: MoreTabViewModel.StorageType

    var body: some View {
        Form {
            ForEach(MoreTabViewModel.StorageType.allCases) { storageType in
                Section(footer: storageType.descriptionView) {
                    Button(action: {
                        selection = storageType
                    }) {
                        HStack {
                            Text(storageType.title)
                                .foregroundColor(.label)
                            Spacer()
                            if selection == storageType {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct StorageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        StorageSelectionView(selection: .constant(.appContainer))
    }
}
