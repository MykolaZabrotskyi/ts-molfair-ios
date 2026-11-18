//
//  ItemsPresenter.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

@MainActor
final class ItemsPresenter {

    // MARK: - Properties

    weak var view: ItemsView?

    private static let generatedItemsCount = 100_000
    private static let batchSize = 5_000

    private let repository: ItemsRepository
    private var isBusy = false

    // MARK: - Init

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    // MARK: - Internal Methods

    func didTapGenerate() {
        run {
            try await self.repository.generate(count: Self.generatedItemsCount, batchSize: Self.batchSize)
            self.view?.showRows([], countText: Self.countText(for: 0))
        }
    }

    func didTapLoad() {
        run {
            let rows = try await self.repository.fetchRows()
            self.view?.showRows(rows, countText: Self.countText(for: rows.count))
        }
    }
}

// MARK: - Private Methods

private extension ItemsPresenter {

    /// Runs `operation` in a `Task` unless another one is still going. The busy flag is set before
    /// the task starts, so a second tap in the same run loop turn is already ignored.
    func run(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !isBusy else { return }
        isBusy = true
        view?.setLoading(true)

        Task {
            do {
                try await operation()
            } catch {
                view?.showError(Self.message(for: error))
            }
            isBusy = false
            view?.setLoading(false)
        }
    }

    static func countText(for count: Int) -> String {
        "Rows: \(count.formatted())"
    }

    static func message(for error: Error) -> String {
        switch error {
        case ItemsRepositoryError.invalidArguments:
            return "Invalid generation parameters."
        default:
            return "Operation failed: \(error.localizedDescription)"
        }
    }
}
