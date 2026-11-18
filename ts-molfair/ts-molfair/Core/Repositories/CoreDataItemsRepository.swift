//
//  CoreDataItemsRepository.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData

final class CoreDataItemsRepository: ItemsRepository {

    // MARK: - Properties

    private static let categoriesCount = 1_000

    private let persistence: PersistenceControllerProtocol
    private let dataGenerator: ItemsDataGeneratorProtocol

    // MARK: - Init

    init(persistence: PersistenceControllerProtocol, dataGenerator: ItemsDataGeneratorProtocol) {
        self.persistence = persistence
        self.dataGenerator = dataGenerator
    }

    // MARK: - ItemsRepository

    /// Everything runs on one background context. Items are written in batches: each batch is saved
    /// and the context is refreshed inside an `autoreleasepool`, so memory stays flat even for
    /// 100 000 objects. `NSBatchInsertRequest` is not used because it cannot set relationships.
    func generate(count: Int, batchSize: Int) async throws {
        guard count >= 0, batchSize > 0 else {
            throw ItemsRepositoryError.invalidArguments
        }

        let context = persistence.newBackgroundContext()
        context.undoManager = nil

        try await deleteAllData(in: context)
        let categoryIDs = try await insertCategories(in: context)
        try await insertItems(count: count, batchSize: batchSize, categoryIDs: categoryIDs, in: context)
    }

    /// Reads only `id` and `title` as dictionaries on a background context. No managed objects are
    /// created, so 100 000 rows stay cheap, and only `Sendable` values leave the context.
    func fetchRows() async throws -> [ItemRow] {
        let context = persistence.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: Item.entityName)
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["id", "title"]

            return try context.fetch(request).compactMap { row in
                guard let id = row["id"] as? UUID, let title = row["title"] as? String else {
                    return nil
                }
                return ItemRow(id: id, title: title)
            }
        }
    }
}

// MARK: - Private Methods

private extension CoreDataItemsRepository {

    /// Items go first and categories second, so no item is left pointing at a deleted category.
    func deleteAllData(in context: NSManagedObjectContext) async throws {
        try await context.perform {
            try Self.deleteAll(Item.self, in: context)
            try Self.deleteAll(ItemCategory.self, in: context)
        }
    }

    func insertCategories(in context: NSManagedObjectContext) async throws -> [NSManagedObjectID] {
        let generator = dataGenerator
        return try await context.perform {
            let categories = (0..<Self.categoriesCount).map { _ in
                let category = ItemCategory(context: context)
                category.id = UUID()
                category.title = generator.makeTitle()
                return category
            }
            try context.save()
            // Only the IDs travel between batches. A batch turns them back into lazy faults,
            // so categories do not stay loaded after the refresh.
            let categoryIDs = categories.map(\.objectID)
            context.refreshAllObjects()
            return categoryIDs
        }
    }

    func insertItems(
        count: Int,
        batchSize: Int,
        categoryIDs: [NSManagedObjectID],
        in context: NSManagedObjectContext
    ) async throws {
        let generator = dataGenerator
        var inserted = 0
        while inserted < count {
            let size = min(batchSize, count - inserted)
            try await context.perform {
                try autoreleasepool {
                    let categories = categoryIDs.compactMap { context.object(with: $0) as? ItemCategory }
                    for _ in 0..<size {
                        let item = Item(context: context)
                        item.id = UUID()
                        item.title = generator.makeTitle()
                        item.value = generator.makeValue()
                        item.createdAt = generator.makeDate()
                        item.category = categories.randomElement()
                    }
                    try context.save()
                    context.refreshAllObjects()
                }
            }
            inserted += size
        }
    }

    static func deleteAll<T: NSManagedObject>(_ type: T.Type, in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        try context.execute(NSBatchDeleteRequest(fetchRequest: request))
    }
}
