//
//  CoreDataItemsRepositoryTests.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData
import XCTest
@testable import ts_molfair

@MainActor
final class CoreDataItemsRepositoryTests: XCTestCase {

    // MARK: - Properties

    private static let categoriesCount = 1_000

    // MARK: - Tests

    func test_generate_createsThousandCategoriesAndTheRequestedNumberOfItems() async throws {
        let sut = makeSUT()

        for (count, batchSize) in [(0, 10), (5, 10), (10, 10), (23, 10), (25, 7)] {
            try await sut.repository.generate(count: count, batchSize: batchSize)

            let storedItems = try await items(in: sut.persistence)
            let categoryCount = try await categoryTitles(in: sut.persistence).count
            XCTAssertEqual(storedItems.count, count, "items for count \(count), batch size \(batchSize)")
            XCTAssertEqual(categoryCount, Self.categoriesCount, "categories for count \(count), batch size \(batchSize)")
        }
    }

    func test_generate_assignsEveryItemACategory() async throws {
        let sut = makeSUT()

        try await sut.repository.generate(count: 30, batchSize: 10)

        let storedItems = try await items(in: sut.persistence)
        XCTAssertEqual(storedItems.count, 30)
        XCTAssertTrue(storedItems.allSatisfy(\.hasCategory))
    }

    func test_generate_writesValuesFromTheInjectedGenerator() async throws {
        let sut = makeSUT(dataGenerator: FixedItemsDataGenerator())

        try await sut.repository.generate(count: 12, batchSize: 5)

        let storedItems = try await items(in: sut.persistence)
        XCTAssertEqual(storedItems.count, 12)
        XCTAssertTrue(storedItems.allSatisfy { $0.title == FixedItemsDataGenerator.title })
        XCTAssertTrue(storedItems.allSatisfy { $0.value == FixedItemsDataGenerator.value })
        XCTAssertTrue(storedItems.allSatisfy { $0.createdAt == FixedItemsDataGenerator.date })
        let titles = try await categoryTitles(in: sut.persistence)
        XCTAssertEqual(Set(titles), [FixedItemsDataGenerator.title])
    }

    func test_generate_replacesPreviousData() async throws {
        let sut = makeSUT()
        try await sut.repository.generate(count: 10, batchSize: 4)
        let firstIDs = Set(try await items(in: sut.persistence).map(\.id))

        try await sut.repository.generate(count: 7, batchSize: 4)

        let secondIDs = Set(try await items(in: sut.persistence).map(\.id))
        let categoryCount = try await categoryTitles(in: sut.persistence).count
        XCTAssertEqual(firstIDs.count, 10)
        XCTAssertEqual(secondIDs.count, 7)
        XCTAssertTrue(firstIDs.isDisjoint(with: secondIDs))
        XCTAssertEqual(categoryCount, Self.categoriesCount)
    }

    func test_generate_withInvalidArguments_throwsAndKeepsTheStoredData() async throws {
        let sut = makeSUT()
        try await sut.repository.generate(count: 5, batchSize: 10)
        let idsBefore = Set(try await items(in: sut.persistence).map(\.id))

        for (count, batchSize) in [(-1, 10), (5, 0), (5, -3)] {
            do {
                try await sut.repository.generate(count: count, batchSize: batchSize)
                XCTFail("Expected an error for count \(count), batch size \(batchSize)")
            } catch {
                guard case ItemsRepositoryError.invalidArguments = error else {
                    return XCTFail("Expected invalidArguments, got \(error)")
                }
            }
        }

        let idsAfter = Set(try await items(in: sut.persistence).map(\.id))
        XCTAssertEqual(idsAfter, idsBefore)
    }

    func test_generate_withInvalidArguments_doesNotTouchThePersistence() async {
        let spy = SpyPersistenceController(base: PersistenceController(inMemory: true))
        let repository = CoreDataItemsRepository(persistence: spy, dataGenerator: ItemsDataGenerator())

        _ = try? await repository.generate(count: -1, batchSize: 10)
        _ = try? await repository.generate(count: 5, batchSize: 0)

        XCTAssertEqual(spy.newBackgroundContextCallCount, 0)
    }

    func test_fetchRows_onEmptyStore_returnsNoRows() async throws {
        let sut = makeSUT()

        let rows = try await sut.repository.fetchRows()

        XCTAssertTrue(rows.isEmpty)
    }

    func test_fetchRows_returnsIdAndTitleOfEveryStoredItem() async throws {
        let sut = makeSUT()
        try await sut.repository.generate(count: 20, batchSize: 8)

        let rows = try await sut.repository.fetchRows()

        let storedItems = try await items(in: sut.persistence)
        XCTAssertEqual(rows.count, 20)
        XCTAssertEqual(Set(rows.map(\.id)).count, 20)
        let storedTitlesByID = Dictionary(uniqueKeysWithValues: storedItems.map { ($0.id, $0.title) })
        XCTAssertEqual(Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.title) }), storedTitlesByID)
    }

    func test_generate_hundredThousandItemsInBatchesOfFiveThousand() async throws {
        let sut = makeSUT()

        try await sut.repository.generate(count: 100_000, batchSize: 5_000)

        let itemCount = try await count(of: Item.entityName, in: sut.persistence)
        let categoryCount = try await count(of: ItemCategory.entityName, in: sut.persistence)
        let itemsWithoutCategory = try await count(of: Item.entityName, matching: "category == nil", in: sut.persistence)
        XCTAssertEqual(itemCount, 100_000)
        XCTAssertEqual(categoryCount, Self.categoriesCount)
        XCTAssertEqual(itemsWithoutCategory, 0)

        let rows = try await sut.repository.fetchRows()
        XCTAssertEqual(rows.count, 100_000)
        XCTAssertEqual(Set(rows.map(\.id)).count, 100_000)
    }
}

// MARK: - Private Methods

private extension CoreDataItemsRepositoryTests {

    struct SUT {
        let repository: CoreDataItemsRepository
        let persistence: PersistenceController
    }

    struct StoredItem: Sendable {
        let id: UUID
        let title: String
        let value: Int64
        let createdAt: Date
        let hasCategory: Bool
    }

    func makeSUT(dataGenerator: ItemsDataGeneratorProtocol = ItemsDataGenerator()) -> SUT {
        let persistence = PersistenceController(inMemory: true)
        let repository = CoreDataItemsRepository(persistence: persistence, dataGenerator: dataGenerator)
        return SUT(repository: repository, persistence: persistence)
    }

    func items(in persistence: PersistenceController) async throws -> [StoredItem] {
        let context = persistence.newBackgroundContext()
        return try await context.perform {
            try context.fetch(NSFetchRequest<Item>(entityName: Item.entityName)).map {
                StoredItem(id: $0.id, title: $0.title, value: $0.value, createdAt: $0.createdAt, hasCategory: $0.category != nil)
            }
        }
    }

    func categoryTitles(in persistence: PersistenceController) async throws -> [String] {
        let context = persistence.newBackgroundContext()
        return try await context.perform {
            try context.fetch(NSFetchRequest<ItemCategory>(entityName: ItemCategory.entityName)).map(\.title)
        }
    }

    func count(of entityName: String, matching format: String? = nil, in persistence: PersistenceController) async throws -> Int {
        let context = persistence.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            request.predicate = format.map { NSPredicate(format: $0) }
            return try context.count(for: request)
        }
    }
}
