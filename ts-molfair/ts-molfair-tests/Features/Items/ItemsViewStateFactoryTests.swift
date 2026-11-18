//
//  ItemsViewStateFactoryTests.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import XCTest
@testable import ts_molfair

@MainActor
final class ItemsViewStateFactoryTests: XCTestCase {

    // MARK: - Properties

    private let sut = ItemsViewStateFactory()

    // MARK: - Tests

    func test_makeLoaded_countTextMatchesNumberOfRows() {
        for count in [0, 1, 1_234] {
            let rows = (0..<count).map { ItemRow(id: UUID(), title: "title \($0)") }

            let state = sut.make(from: .loaded(rows: rows))

            guard case .loaded(let loadedRows, let countText) = state.kind else {
                return XCTFail("Expected a loaded state for \(count) rows")
            }
            XCTAssertEqual(loadedRows.count, count)
            XCTAssertEqual(countText, "Rows: \(count.formatted())")
        }
    }

    func test_makeError_messageContainsLocalizedDescription() {
        let error = TestError.failed

        let state = sut.make(from: .error(error))

        guard case .error(let message) = state.kind else {
            return XCTFail("Expected an error state")
        }
        XCTAssertTrue(message.contains(error.localizedDescription))
    }

    func test_make_alwaysProvidesNonEmptyTexts() {
        let inputs: [ItemsViewStateFactoryInput] = [
            .loading,
            .loaded(rows: []),
            .error(TestError.failed)
        ]

        for input in inputs {
            let texts = sut.make(from: input).texts

            XCTAssertFalse(texts.navigationTitle.isEmpty)
            XCTAssertFalse(texts.generateButtonTitle.isEmpty)
            XCTAssertFalse(texts.loadButtonTitle.isEmpty)
            XCTAssertFalse(texts.errorTitle.isEmpty)
            XCTAssertFalse(texts.errorOkAction.isEmpty)
        }
    }
}

// MARK: - Private Methods

private extension ItemsViewStateFactoryTests {

    enum TestError: LocalizedError {
        case failed

        var errorDescription: String? {
            "Something went wrong in the test"
        }
    }
}
