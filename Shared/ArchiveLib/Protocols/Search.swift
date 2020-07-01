//
//  Search.swift
//  ArchiveLib
//
//  Created by Julian Kahnert on 13.11.18.
//

import Foundation

/// Scope, which defines the documents that should be searched.
public enum SearchScope {

    /// Search the whole archive.
    case all

    /// Search in a specific year.
    case year(year: String)
}

/// Protocol for objects which should be searched.
public protocol Searchable: Hashable {

    /// Term which will be used for the search
    var searchTerm: String { get }
}

/// Protocol for objects which can search.
public protocol Searcher {

    /// Element which will be searched.
    associatedtype Element: Searchable

    /// Set of all the searchable elements.
    var allSearchElements: Set<Element> { get }

    // swiftlint:disable missing_docs
    func filter(by searchTerm: String) -> Set<Element>
    func filter(by searchTerms: [String]) -> Set<Element>
    // swiftlint:enable missing_docs
}

/// Implementation of the Searcher functions.
public extension Searcher {

    /// Filter the "Searchable" objects by a search term.
    ///
    /// - Parameter searchTerm: Searchable object must contain the specified search term.
    /// - Returns: All objects which stickt to the constraints.
    func filter(by searchTerm: String) -> Set<Element> {
        return filter(by: searchTerm, allSearchElements)
    }

    /// Filter the "Searchable" objects by all search terms.
    ///
    /// - Parameter searchTerms: Searchable object must contain all the specified search terms.
    /// - Returns: All objects which stickt to the constraints.
    func filter(by searchTerms: [String]) -> Set<Element> {

        // all searchTerms must be machted, sorted by count to decrease the number of search elements
        let sortedSearchTerms = searchTerms.sorted { $0.count > $1.count }

        var currentElements = allSearchElements
        for searchTerm in sortedSearchTerms {

            // skip all further iterations
            if currentElements.isEmpty {
                break
            }

            currentElements = filter(by: searchTerm, currentElements)
        }
        return currentElements
    }

    /// Internal filter function.
    ///
    /// - Parameters:
    ///   - searchTerm: Searchable object must contain the specified search term.
    ///   - searchElements: Objects which should be searched.
    /// - Returns: All objects which stickt to the constraints.
    private func filter(by searchTerm: String, _ searchElements: Set<Element>) -> Set<Element> {
        return Set(searchElements.filter { $0.searchTerm.lowercased().contains(searchTerm.lowercased()) })
    }
}
