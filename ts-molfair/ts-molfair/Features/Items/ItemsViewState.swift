//
//  ItemsViewState.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

struct ItemsViewState {

    // MARK: - Nested Types

    struct Texts {
        let navigationTitle: String
        let generateButtonTitle: String
        let loadButtonTitle: String
        let errorTitle: String
        let errorOkAction: String
        let emptyTitle: String
        let emptyMessage: String
        let spinnerAccessibilityLabel: String
    }

    enum Kind {
        case loading
        case loaded(rows: [ItemRow], countText: String)
        case error(String)
    }

    // MARK: - Properties

    let texts: Texts
    let kind: Kind
}
