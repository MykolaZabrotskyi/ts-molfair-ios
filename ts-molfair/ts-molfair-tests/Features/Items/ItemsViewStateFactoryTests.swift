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
        let narrowNoBreakSpace = "\u{202F}"
        let expectedTexts = [
            0: "Rows: 0",
            1: "Rows: 1",
            999: "Rows: 999",
            1_234: "Rows: 1\(narrowNoBreakSpace)234",
            100_000: "Rows: 100\(narrowNoBreakSpace)000"
        ]

        for (count, expectedText) in expectedTexts {
            let rows = (0..<count).map { ItemRow(id: UUID(), title: "title \($0)") }

            let state = sut.make(from: .loaded(rows: rows))

            guard case .loaded(let loadedRows, let countText) = state.kind else {
                return XCTFail("Expected a loaded state for \(count) rows")
            }
            XCTAssertEqual(loadedRows.count, count)
            XCTAssertEqual(countText, expectedText)
        }
    }

    func test_makeTexts_emptyMessageMentionsTheGeneratedCount() {
        let factory = ItemsViewStateFactory(generatedItemsCount: 100_000)

        let texts = factory.make(from: .loading).texts

        XCTAssertTrue(texts.emptyMessage.contains("100\u{202F}000"))
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
            XCTAssertFalse(texts.emptyTitle.isEmpty)
            XCTAssertFalse(texts.emptyMessage.isEmpty)
            XCTAssertFalse(texts.spinnerAccessibilityLabel.isEmpty)
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
