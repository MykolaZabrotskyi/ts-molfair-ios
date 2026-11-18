//
//  PersistenceControllerTests.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData
import XCTest
@testable import ts_molfair

@MainActor
final class PersistenceControllerTests: XCTestCase {

    // MARK: - Tests

    func test_init_inMemory_usesTheDevNullStore() {
        let sut = PersistenceController(inMemory: true)

        let stores = sut.container.persistentStoreCoordinator.persistentStores

        XCTAssertEqual(stores.count, 1)
        XCTAssertEqual(stores.first?.url?.path, "/dev/null")
    }

    func test_init_loadsTheModelWithBothEntities() {
        let sut = PersistenceController(inMemory: true)

        let entityNames = Set(sut.container.managedObjectModel.entitiesByName.keys)

        XCTAssertEqual(entityNames, [ItemCategory.entityName, Item.entityName])
    }

    func test_newBackgroundContext_usesItsOwnQueueOnTheSameStore() {
        let sut = PersistenceController(inMemory: true)

        let context = sut.newBackgroundContext()

        XCTAssertEqual(context.concurrencyType, .privateQueueConcurrencyType)
        XCTAssertTrue(context.persistentStoreCoordinator === sut.container.persistentStoreCoordinator)
    }

    func test_newBackgroundContext_returnsANewContextEachTime() {
        let sut = PersistenceController(inMemory: true)

        let first = sut.newBackgroundContext()
        let second = sut.newBackgroundContext()

        XCTAssertFalse(first === second)
    }

    func test_inMemoryControllers_doNotShareData() async throws {
        let first = PersistenceController(inMemory: true)
        let second = PersistenceController(inMemory: true)
        let context = first.newBackgroundContext()

        try await context.perform {
            let category = ItemCategory(context: context)
            category.id = UUID()
            category.title = "only in the first store"
            try context.save()
        }

        let firstCount = try await categoryCount(in: first)
        let secondCount = try await categoryCount(in: second)
        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 0)
    }

    func test_controller_conformsToPersistenceControllerProtocol() {
        let sut: PersistenceControllerProtocol = PersistenceController(inMemory: true)

        XCTAssertEqual(sut.newBackgroundContext().concurrencyType, .privateQueueConcurrencyType)
    }
}

// MARK: - Private Methods

private extension PersistenceControllerTests {

    func categoryCount(in persistence: PersistenceController) async throws -> Int {
        let context = persistence.newBackgroundContext()
        return try await context.perform {
            try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: ItemCategory.entityName))
        }
    }
}
