//
//  ItemsDataGeneratorTests.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import XCTest
@testable import ts_molfair

@MainActor
final class ItemsDataGeneratorTests: XCTestCase {

    // MARK: - Properties

    private static let sampleSize = 1_000

    private let sut = ItemsDataGenerator()

    // MARK: - Tests

    func test_makeTitle_returnsEightLowercaseLetters() {
        for _ in 0..<Self.sampleSize {
            let title = sut.makeTitle()

            XCTAssertEqual(title.count, 8)
            XCTAssertTrue(title.allSatisfy { $0.isASCII && $0.isLetter && $0.isLowercase }, "Unexpected title: \(title)")
        }
    }

    func test_makeTitle_isRandom() {
        let titles = (0..<Self.sampleSize).map { _ in sut.makeTitle() }

        XCTAssertGreaterThan(Set(titles).count, 990)
    }

    func test_makeValue_staysInRangeAndVaries() {
        let values = (0..<Self.sampleSize).map { _ in sut.makeValue() }

        XCTAssertTrue(values.allSatisfy { (0...1_000_000).contains($0) })
        XCTAssertGreaterThan(Set(values).count, 900)
    }

    func test_makeDate_isWithinTheLastYear() {
        let earliestAllowed = Date().addingTimeInterval(-365 * 24 * 60 * 60)

        let dates = (0..<Self.sampleSize).map { _ in sut.makeDate() }
        let latestAllowed = Date()

        XCTAssertTrue(dates.allSatisfy { $0 >= earliestAllowed && $0 <= latestAllowed })
        XCTAssertGreaterThan(Set(dates).count, 990)
    }
}
