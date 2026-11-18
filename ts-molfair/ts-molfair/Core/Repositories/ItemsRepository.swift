//
//  ItemsRepository.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

protocol ItemsRepository {

    // MARK: - Internal Methods

    /// Replaces all stored data with 1 000 categories and `count` items.
    /// Throws `ItemsRepositoryError.invalidArguments` if `count` is negative or `batchSize` is not positive.
    func generate(count: Int, batchSize: Int) async throws

    /// Returns the id and title of every stored item as plain values that are safe to pass to the main thread.
    func fetchRows() async throws -> [ItemRow]
}

enum ItemsRepositoryError: Error {
    case invalidArguments
}
