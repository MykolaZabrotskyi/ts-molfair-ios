//
//  ItemsPresenter.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

enum ItemsPresenterAction {
    case onLoad
    case onGenerateTapped
    case onLoadTapped
}

@MainActor
protocol ItemsPresenterProtocol: AnyObject {
    func perform(with action: ItemsPresenterAction)
}

@MainActor
final class ItemsPresenter {

    // MARK: - Properties

    private static let generatedItemsCount = 100_000
    private static let batchSize = 5_000

    private weak var viewController: ItemsViewControllerProtocol?
    private let repository: ItemsRepository
    private let viewStateFactory: ItemsViewStateFactoryProtocol
    private var rows: [ItemRow] = []
    private var isLoading = false

    // MARK: - Init

    init(
        viewController: ItemsViewControllerProtocol,
        repository: ItemsRepository,
        viewStateFactory: ItemsViewStateFactoryProtocol
    ) {
        self.viewController = viewController
        self.repository = repository
        self.viewStateFactory = viewStateFactory
    }
}

// MARK: - ItemsPresenterProtocol

extension ItemsPresenter: ItemsPresenterProtocol {

    func perform(with action: ItemsPresenterAction) {
        switch action {
        case .onLoad:
            render(.loaded(rows: rows))

        case .onGenerateTapped:
            generate()

        case .onLoadTapped:
            load()
        }
    }
}

// MARK: - Private Methods

private extension ItemsPresenter {

    /// The `isLoading` check runs inside the task. Tasks started from the main actor run one after another,
    /// so a second tap sees the flag already set by the first and is ignored.
    func generate() {
        Task { [weak self] in
            guard let self, !isLoading else { return }
            isLoading = true
            render(.loading)

            do {
                try await repository.generate(count: Self.generatedItemsCount, batchSize: Self.batchSize)
                isLoading = false
                render(.loaded(rows: rows))
            } catch {
                isLoading = false
                render(.error(error))
            }
        }
    }

    func load() {
        Task { [weak self] in
            guard let self, !isLoading else { return }
            isLoading = true
            render(.loading)

            do {
                rows = try await repository.fetchRows()
                isLoading = false
                render(.loaded(rows: rows))
            } catch {
                isLoading = false
                render(.error(error))
            }
        }
    }

    func render(_ input: ItemsViewStateFactoryInput) {
        viewController?.render(with: viewStateFactory.make(from: input))
    }
}
