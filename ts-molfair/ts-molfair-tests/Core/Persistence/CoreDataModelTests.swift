//
//  CoreDataModelTests.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData
import XCTest
@testable import ts_molfair

@MainActor
final class CoreDataModelTests: XCTestCase {

    // MARK: - Tests

    func test_categoryItems_isToManyCascadeRelationshipWithInverse() throws {
        let persistence = PersistenceController(inMemory: true)
        let items = try relationship("items", of: ItemCategory.entityName, in: persistence)

        XCTAssertTrue(items.isToMany)
        XCTAssertTrue(items.isOptional)
        XCTAssertEqual(items.deleteRule, .cascadeDeleteRule)
        XCTAssertEqual(items.destinationEntity?.name, Item.entityName)
        XCTAssertEqual(items.inverseRelationship?.name, "category")
    }

    func test_itemCategory_isToOneNullifyRelationshipWithInverse() throws {
        let persistence = PersistenceController(inMemory: true)
        let category = try relationship("category", of: Item.entityName, in: persistence)

        XCTAssertFalse(category.isToMany)
        XCTAssertTrue(category.isOptional)
        XCTAssertEqual(category.deleteRule, .nullifyDeleteRule)
        XCTAssertEqual(category.destinationEntity?.name, ItemCategory.entityName)
        XCTAssertEqual(category.inverseRelationship?.name, "items")
    }

    func test_entities_haveTheExpectedAttributes() throws {
        let persistence = PersistenceController(inMemory: true)
        let model = persistence.container.managedObjectModel

        let category = try XCTUnwrap(model.entitiesByName[ItemCategory.entityName])
        XCTAssertEqual(category.attributesByName["id"]?.attributeType, .UUIDAttributeType)
        XCTAssertEqual(category.attributesByName["title"]?.attributeType, .stringAttributeType)

        let item = try XCTUnwrap(model.entitiesByName[Item.entityName])
        XCTAssertEqual(item.attributesByName["id"]?.attributeType, .UUIDAttributeType)
        XCTAssertEqual(item.attributesByName["title"]?.attributeType, .stringAttributeType)
        XCTAssertEqual(item.attributesByName["value"]?.attributeType, .integer64AttributeType)
        XCTAssertEqual(item.attributesByName["createdAt"]?.attributeType, .dateAttributeType)
    }

    func test_settingItemCategory_updatesCategoryItems() {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let category = makeCategory(in: context)

        let item = makeItem(in: context, category: category)

        XCTAssertEqual(category.items, [item])
        XCTAssertTrue(item.category === category)
    }

    func test_deletingCategory_deletesItsItems() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let category = makeCategory(in: context)
        _ = makeItem(in: context, category: category)
        _ = makeItem(in: context, category: category)
        try context.save()

        context.delete(category)
        try context.save()

        XCTAssertEqual(try itemCount(in: context), 0)
    }

    func test_deletingItem_removesItFromCategoryAndKeepsTheCategory() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let category = makeCategory(in: context)
        let first = makeItem(in: context, category: category)
        let second = makeItem(in: context, category: category)
        try context.save()

        context.delete(first)
        try context.save()

        XCTAssertEqual(category.items, [second])
        XCTAssertFalse(category.isDeleted)
    }

    func test_categoryWithoutItems_canBeSaved() {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        _ = makeCategory(in: context)

        XCTAssertNoThrow(try context.save())
    }
}

// MARK: - Private Methods

private extension CoreDataModelTests {

    func relationship(
        _ name: String,
        of entityName: String,
        in persistence: PersistenceController
    ) throws -> NSRelationshipDescription {
        let entity = try XCTUnwrap(persistence.container.managedObjectModel.entitiesByName[entityName])
        return try XCTUnwrap(entity.relationshipsByName[name])
    }

    func makeCategory(in context: NSManagedObjectContext) -> ItemCategory {
        let category = ItemCategory(context: context)
        category.id = UUID()
        category.title = "category"
        return category
    }

    func makeItem(in context: NSManagedObjectContext, category: ItemCategory) -> Item {
        let item = Item(context: context)
        item.id = UUID()
        item.title = "item"
        item.value = 1
        item.createdAt = Date()
        item.category = category
        return item
    }

    func itemCount(in context: NSManagedObjectContext) throws -> Int {
        try context.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: Item.entityName))
    }
}
