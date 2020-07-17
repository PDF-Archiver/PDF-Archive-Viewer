//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Julian Kahnert on 24.06.20.
//

//@testable import PDFArchiver
import XCTest

extension URL {

    func getFilesRecursive(fileProperties: [URLResourceKey] = []) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: self, includingPropertiesForKeys: fileProperties) else { return [] }

        var files = [URL]()
        for case let file as URL in enumerator {
            guard !file.hasDirectoryPath else { continue }
            files.append(file)
        }
        return files
    }

}

//swiftlint:disable:next type_name
class Tests_iOS: XCTestCase {

    var tempDir: URL?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)

        guard let tempDir = tempDir else { return }
        for folderIndex in 0..<20 {
            let folder = tempDir.appendingPathComponent("\(folderIndex)")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            for _ in 0..<50 {
                let file = folder.appendingPathComponent(UUID().uuidString)
                try "TEST".write(to: file, atomically: true, encoding: .utf8)
            }
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        guard let tempDir = tempDir else { return }
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testGetFilesPerformanceAll() throws {
        guard let path = tempDir else { return }
        var files = [URL]()

        measure {
            files = path.getFilesRecursive(fileProperties: [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .fileSizeKey, .localizedNameKey])
        }

        XCTAssert(files.count == 1000)
    }

    func testGetFilesPerformanceNoLocalizedName() throws {
        guard let path = tempDir else { return }
        var files = [URL]()

        measure {
            files = path.getFilesRecursive(fileProperties: [.ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsDownloadingKey, .fileSizeKey])
        }

        XCTAssert(files.count == 1000)
    }

    func testGetFilesPerformanceOnlyLocalizedName() throws {
        guard let path = tempDir else { return }
        var files = [URL]()

        measure {
            files = path.getFilesRecursive(fileProperties: [.localizedNameKey])
        }
        XCTAssert(files.count == 1000)
    }

//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
