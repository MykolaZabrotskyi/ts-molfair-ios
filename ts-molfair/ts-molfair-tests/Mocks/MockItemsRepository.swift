//
//  MockItemsRepository.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation
@testable import ts_molfair

final class MockItemsRepository: ItemsRepository {

    // MARK: - Nested Types

    struct GenerateCall: Equatable {
        let count: Int
        let batchSize: Int
    }

    // MARK: - Properties

    var rows: [ItemRow] = []
    var generateError: Error?
    var fetchError: Error?
    var gate: AsyncGate?

    var generateCalls: [GenerateCall] {
        lock.withLock { recordedGenerateCalls }
    }

    var fetchRowsCallCount: Int {
        lock.withLock { recordedFetchRowsCallCount }
    }

    private let lock = NSLock()
    private var recordedGenerateCalls: [GenerateCall] = []
    private var recordedFetchRowsCallCount = 0
}

// MARK: - ItemsRepository

extension MockItemsRepository {

    func generate(count: Int, batchSize: Int) async throws {
        lock.withLock { recordedGenerateCalls.append(GenerateCall(count: count, batchSize: batchSize)) }
        await gate?.wait()
        if let generateError {
            throw generateError
        }
    }

    func fetchRows() async throws -> [ItemRow] {
        lock.withLock { recordedFetchRowsCallCount += 1 }
        await gate?.wait()
        if let fetchError {
            throw fetchError
        }
        return rows
    }
}
