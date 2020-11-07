//
//  PlatfromWrapper.swift
//  
//
//  Created by Julian Kahnert on 07.11.20.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public func open(_ url: URL) {
    #if os(macOS)
    NSWorkspace.shared.open(url)
    #else
    UIApplication.shared.open(writeReviewURL)
    #endif
}

#if os(macOS)
import SwiftUIX
// TODO: do these symbols exist on macOS 11?
extension Label where Title == Text, Icon == Image {
    /// Creates a label with a system icon image and a title generated from a
    /// localized string.
    @available(iOS 14.0, OSX 10.16, tvOS 14.0, watchOS 7.0, *)
    public init(_ titleKey: LocalizedStringKey, systemImage name: SanFranciscoSymbolName) {
        self.init(titleKey, systemImage: name.rawValue)
    }
}
#endif
