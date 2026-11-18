//
//  SpyItemsViewController.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import XCTest
@testable import ts_molfair

@MainActor
final class SpyItemsViewController {

    // MARK: - Properties

    private(set) var viewStates: [ItemsViewState] = []

    private var loadingExpectation: XCTestExpectation?
    private var finalStateExpectation: XCTestExpectation?
    private var hasSeenLoading = false

    // MARK: - Internal Methods

    func expectLoading() -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "Loading state rendered")
        loadingExpectation = expectation
        return expectation
    }

    /// Fulfilled by the first `loaded` or `error` state that follows a `loading` state.
    /// The `loaded` state that `.onLoad` renders on its own does not count.
    func expectFinalState() -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "Final state rendered")
        finalStateExpectation = expectation
        return expectation
    }
}

// MARK: - ItemsViewControllerProtocol

extension SpyItemsViewController: ItemsViewControllerProtocol {

    func render(with viewState: ItemsViewState) {
        viewStates.append(viewState)

        switch viewState.kind {
        case .loading:
            hasSeenLoading = true
            loadingExpectation?.fulfill()
            loadingExpectation = nil

        case .loaded, .error:
            guard hasSeenLoading else { return }
            hasSeenLoading = false
            finalStateExpectation?.fulfill()
            finalStateExpectation = nil
        }
    }
}
