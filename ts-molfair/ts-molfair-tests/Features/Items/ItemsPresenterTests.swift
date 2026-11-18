//
//  ItemsPresenterTests.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import XCTest
@testable import ts_molfair

@MainActor
final class ItemsPresenterTests: XCTestCase {

    // MARK: - Properties

    private static let timeout: TimeInterval = 5

    // MARK: - Tests

    func test_onLoad_rendersEmptyLoadedState() {
        let sut = makeSUT()

        sut.presenter.perform(with: .onLoad)

        XCTAssertEqual(sut.viewController.viewStates.count, 1)
        guard case .loaded(let rows, let countText)? = sut.viewController.viewStates.first?.kind else {
            return XCTFail("Expected a loaded state")
        }
        XCTAssertTrue(rows.isEmpty)
        XCTAssertEqual(countText, expectedCountText(for: 0))
        XCTAssertEqual(sut.repository.fetchRowsCallCount, 0)
        XCTAssertTrue(sut.repository.generateCalls.isEmpty)
    }

    func test_onLoadTapped_rendersLoadingThenLoaded() async {
        let sut = makeSUT(rows: makeRows(3))
        let finished = sut.viewController.expectFinalState()

        sut.presenter.perform(with: .onLoadTapped)
        await fulfillment(of: [finished], timeout: Self.timeout)

        XCTAssertEqual(sut.viewController.viewStates.count, 2)
        guard case .loading = sut.viewController.viewStates[0].kind else {
            return XCTFail("Expected loading as the first state")
        }
        guard case .loaded = sut.viewController.viewStates[1].kind else {
            return XCTFail("Expected loaded as the second state")
        }
    }

    func test_onLoadTapped_rendersRowsAndCountText() async {
        let rows = makeRows(3)
        let sut = makeSUT(rows: rows)
        let finished = sut.viewController.expectFinalState()

        sut.presenter.perform(with: .onLoadTapped)
        await fulfillment(of: [finished], timeout: Self.timeout)

        guard case .loaded(let loadedRows, let countText)? = sut.viewController.viewStates.last?.kind else {
            return XCTFail("Expected a loaded state")
        }
        XCTAssertEqual(loadedRows.map(\.id), rows.map(\.id))
        XCTAssertEqual(loadedRows.map(\.title), rows.map(\.title))
        XCTAssertEqual(countText, expectedCountText(for: 3))
    }

    func test_onLoadTapped_whenRepositoryFails_rendersLoadingThenError() async {
        let sut = makeSUT()
        sut.repository.fetchError = TestError.failed
        let finished = sut.viewController.expectFinalState()

        sut.presenter.perform(with: .onLoadTapped)
        await fulfillment(of: [finished], timeout: Self.timeout)

        XCTAssertEqual(sut.viewController.viewStates.count, 2)
        guard case .loading = sut.viewController.viewStates[0].kind else {
            return XCTFail("Expected loading as the first state")
        }
        guard case .error(let message) = sut.viewController.viewStates[1].kind else {
            return XCTFail("Expected an error as the second state")
        }
        XCTAssertTrue(message.contains(TestError.failed.localizedDescription))
    }

    func test_tapsWhileLoading_areIgnored() async {
        let sut = makeSUT(rows: makeRows(2))
        let gate = AsyncGate()
        sut.repository.gate = gate
        let loadingRendered = sut.viewController.expectLoading()

        sut.presenter.perform(with: .onLoadTapped)
        await fulfillment(of: [loadingRendered], timeout: Self.timeout)

        // The first load is held at the gate, so it is still running for both taps below.
        sut.presenter.perform(with: .onLoadTapped)
        sut.presenter.perform(with: .onGenerateTapped)
        // The tasks of the two ignored taps are already queued on the main actor and run during this yield.
        await Task.yield()

        let finished = sut.viewController.expectFinalState()
        gate.open()
        await fulfillment(of: [finished], timeout: Self.timeout)

        XCTAssertEqual(sut.repository.fetchRowsCallCount, 1)
        XCTAssertTrue(sut.repository.generateCalls.isEmpty)
        XCTAssertEqual(sut.viewController.viewStates.count, 2)
        guard case .loading = sut.viewController.viewStates[0].kind,
              case .loaded = sut.viewController.viewStates[1].kind else {
            return XCTFail("Expected exactly loading, then loaded")
        }
    }

    func test_onGenerateTapped_callsGenerateWithExpectedArguments() async {
        let sut = makeSUT()
        let finished = sut.viewController.expectFinalState()

        sut.presenter.perform(with: .onGenerateTapped)
        await fulfillment(of: [finished], timeout: Self.timeout)

        XCTAssertEqual(sut.repository.generateCalls, [MockItemsRepository.GenerateCall(count: 100_000, batchSize: 5_000)])
        XCTAssertEqual(sut.repository.fetchRowsCallCount, 0)
    }

    func test_onGenerateTapped_keepsRowsAlreadyShown() async {
        let sut = makeSUT(rows: makeRows(3))
        let loaded = sut.viewController.expectFinalState()
        sut.presenter.perform(with: .onLoadTapped)
        await fulfillment(of: [loaded], timeout: Self.timeout)

        let generated = sut.viewController.expectFinalState()
        sut.presenter.perform(with: .onGenerateTapped)
        await fulfillment(of: [generated], timeout: Self.timeout)

        XCTAssertEqual(sut.viewController.viewStates.count, 4)
        guard case .loaded(let rows, let countText) = sut.viewController.viewStates[3].kind else {
            return XCTFail("Expected a loaded state after generate")
        }
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(countText, expectedCountText(for: 3))
    }
}

// MARK: - Private Methods

private extension ItemsPresenterTests {

    struct SUT {
        let presenter: ItemsPresenter
        let viewController: SpyItemsViewController
        let repository: MockItemsRepository
    }

    enum TestError: LocalizedError {
        case failed

        var errorDescription: String? {
            "Repository failed"
        }
    }

    func makeSUT(rows: [ItemRow] = []) -> SUT {
        let repository = MockItemsRepository()
        repository.rows = rows
        let viewController = SpyItemsViewController()
        let presenter = ItemsPresenter(
            viewController: viewController,
            repository: repository,
            viewStateFactory: ItemsViewStateFactory()
        )
        return SUT(presenter: presenter, viewController: viewController, repository: repository)
    }

    func makeRows(_ count: Int) -> [ItemRow] {
        (0..<count).map { ItemRow(id: UUID(), title: "title \($0)") }
    }

    /// Only used for counts below one thousand, where no grouping separator is involved.
    func expectedCountText(for count: Int) -> String {
        "Rows: \(count)"
    }
}
