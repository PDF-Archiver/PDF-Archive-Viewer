//
//  Log.swift
//
//
//  Created by Julian Kahnert on 18.07.20.
//

import Logging

protocol Log {
    var log: Logger { get }
}

extension Log {
    static var log: Logger {
        Logger(label: String(describing: self))
    }
    var log: Logger {
        Self.log
    }
}

extension Logger {
    func assertOrError(_ message: @autoclosure () -> Logger.Message,
                      metadata: @autoclosure () -> Logger.Metadata? = nil,
                      source: @autoclosure () -> String? = nil,
                      file: String = #file, function: String = #function, line: UInt = #line) {
        assertionFailure(message().description)
        self.error(message(), metadata: metadata(), file: file, function: function, line: line)
    }

    func assertOrCritical(_ message: @autoclosure () -> Logger.Message,
                      metadata: @autoclosure () -> Logger.Metadata? = nil,
                      source: @autoclosure () -> String? = nil,
                      file: String = #file, function: String = #function, line: UInt = #line) {
        assertionFailure(message().description)
        self.critical(message(), metadata: metadata(), file: file, function: function, line: line)
    }
}
