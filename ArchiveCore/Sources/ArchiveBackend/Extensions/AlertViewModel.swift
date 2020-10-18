//
//  AlertViewModel.swift
//  
//
//  Created by Julian Kahnert on 13.10.20.
//

extension AlertViewModel {
    public static func createAndPostNoICloudDrive() {
        AlertViewModel.createAndPost(title: "Attention",
                                     message: "Could not find iCloud Drive.",
                                     primaryButtonTitle: "OK")
    }
}
