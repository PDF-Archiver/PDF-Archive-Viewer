//
//  FilterItem+FilterCache.swift
//  
//
//  Created by Julian Kahnert on 09.09.20.
//

import Foundation

extension FilterItem {
    public final class FilterCache {
        public typealias DateTriple = (year: String, yearMonth: String, yearMonthDay: String)

        public let yearFormatter: DateFormatter = .with("yyyy")
        public let yearMonthFormatter: DateFormatter = .with("yyyyMM")
        public let yearMonthDayFormatter: DateFormatter = .with("yyyyMMdd")

        public var dateMap: [Date: DateTriple] = [:]

        public func getTriple(for date: Date) -> DateTriple {
            // TODO: add sync queue here

            if let triple = dateMap[date] {
                return triple
            } else {
                let year = yearFormatter.string(from: date)
                let yearMonth = yearMonthFormatter.string(from: date)
                let yearMonthDay = yearMonthDayFormatter.string(from: date)
                let triple: DateTriple = (year, yearMonth, yearMonthDay)

                dateMap[date] = triple
                return triple
            }
        }
    }
}
