//
//  Tag.swift
//  ArchiveLib
//
//  Created by Julian Kahnert on 13.11.18.
//

import Foundation

/// Struct  which represents a Tag.
public struct Tag {

    /// Name of the tag.
    public let name: String

    /// Count of how many tags with this name exist.
    public var count: Int

    /// Create a new tag.
    /// New tags should only be created by the TagManager in this package.
    ///
    /// - Parameters:
    ///   - name: Name of the Tag.
    ///   - count: Number which indicates how many times this tag is used.
    init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

extension Tag: Identifiable, Hashable, Comparable, CustomStringConvertible {

    public var id: String {
        return name
    }

    public static func < (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name < rhs.name
    }

    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name == rhs.name
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    public var description: String { return "\(name) (\(count))" }
}

extension Tag: Searchable {
    public var searchTerm: String {
        return name
    }
}

extension Tag: CustomComparable {
    public func isBefore(_ other: Tag, _ sort: NSSortDescriptor) throws -> Bool {
        if sort.key == "name" {
            return sort.ascending ? name < other.name : name > other.name
        } else if sort.key == "count" {
            return sort.ascending ? count < other.count : count > other.count
        }
        throw SortDescriptorError.invalidKey
    }
}
