//
//  ArrayUrlTests.swift
//  
//
//  Created by Julian Kahnert on 22.08.20.
//

@testable import ArchiveCore
import Foundation
import XCTest

class ArrayURLTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    func testParents() {
        let url1 = URL(string: "/test/folder1/archive/untagged")!
        let url2 = URL(string: "/test/folder1/archive")!
        let url3 = URL(string: "/test/folder2/scans")!
        let url4 = URL(string: "/test/folder1/archive/untagged/temp")!
        let url5 = URL(string: "/test/folder2")!

        let folders = [url1, url2, url3, url4, url5].getUniqueParents()

        XCTAssert(folders.contains(url2))
        XCTAssert(folders.contains(url5))
        XCTAssertEqual(folders.count, 2)
    }
}
