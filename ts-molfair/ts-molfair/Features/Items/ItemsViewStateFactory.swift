//
//  ItemsViewStateFactory.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

enum ItemsViewStateFactoryInput {
    case loading
    case loaded(rows: [ItemRow])
    case error(Error)
}

protocol ItemsViewStateFactoryProtocol {
    func make(from input: ItemsViewStateFactoryInput) -> ItemsViewState
}

final class ItemsViewStateFactory {}

// MARK: - ItemsViewStateFactoryProtocol

extension ItemsViewStateFactory: ItemsViewStateFactoryProtocol {

    func make(from input: ItemsViewStateFactoryInput) -> ItemsViewState {
        ItemsViewState(texts: makeTexts(), kind: makeKind(from: input))
    }
}

// MARK: - Private Methods

private extension ItemsViewStateFactory {

    func makeTexts() -> ItemsViewState.Texts {
        ItemsViewState.Texts(
            navigationTitle: String(localized: "Items"),
            generateButtonTitle: String(localized: "Generate"),
            loadButtonTitle: String(localized: "Load"),
            errorTitle: String(localized: "Error"),
            errorOkAction: String(localized: "OK")
        )
    }

    func makeKind(from input: ItemsViewStateFactoryInput) -> ItemsViewState.Kind {
        switch input {
        case .loading:
            return .loading

        case .loaded(let rows):
            return .loaded(rows: rows, countText: makeCountText(for: rows.count))

        case .error(let error):
            return .error(makeErrorMessage(from: error))
        }
    }

    func makeCountText(for count: Int) -> String {
        String(localized: "Rows: \(count.formatted())")
    }

    func makeErrorMessage(from error: Error) -> String {
        switch error {
        case ItemsRepositoryError.invalidArguments:
            return String(localized: "Invalid generation parameters.")

        default:
            return String(localized: "Operation failed: \(error.localizedDescription)")
        }
    }
}
