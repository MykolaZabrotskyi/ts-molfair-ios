//
//  FixedItemsDataGenerator.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation
@testable import ts_molfair

struct FixedItemsDataGenerator: ItemsDataGeneratorProtocol {

    // MARK: - Properties

    static let title = "fixed title"
    static let value: Int64 = 42
    static let date = Date(timeIntervalSince1970: 1_000_000)
}

// MARK: - ItemsDataGeneratorProtocol

extension FixedItemsDataGenerator {

    func makeTitle() -> String {
        Self.title
    }

    func makeValue() -> Int64 {
        Self.value
    }

    func makeDate() -> Date {
        Self.date
    }
}
