//
//  ItemsDataGenerator.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

protocol ItemsDataGeneratorProtocol: Sendable {
    func makeTitle() -> String
    func makeValue() -> Int64
    func makeDate() -> Date
}

final class ItemsDataGenerator {

    // MARK: - Properties

    private static let titleLength = 8
    private static let titleLetters = Array("abcdefghijklmnopqrstuvwxyz")
    private static let valueRange: ClosedRange<Int64> = 0...1_000_000
    private static let secondsInYear: TimeInterval = 365 * 24 * 60 * 60
}

// MARK: - ItemsDataGeneratorProtocol

extension ItemsDataGenerator: ItemsDataGeneratorProtocol {

    func makeTitle() -> String {
        String((0..<Self.titleLength).compactMap { _ in Self.titleLetters.randomElement() })
    }

    func makeValue() -> Int64 {
        Int64.random(in: Self.valueRange)
    }

    /// A random moment within the last year.
    func makeDate() -> Date {
        Date(timeIntervalSinceNow: -TimeInterval.random(in: 0...Self.secondsInYear))
    }
}
