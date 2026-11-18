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
    private static let titleLength = 8
    private static let titleLetters = Array("abcdefghijklmnopqrstuvwxyz")
    private static let valueRange: ClosedRange<Int64> = 0...1_000_000
    private static let secondsInYear: TimeInterval = 365 * 24 * 60 * 60

    private let persistence: PersistenceController

    // MARK: - Init

    init(persistence: PersistenceController) {
        self.persistence = persistence
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
            let request = NSFetchRequest<NSDictionary>(entityName: String(describing: Item.self))
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
            try Self.deleteAll(Category.self, in: context)
        }
    }

    func insertCategories(in context: NSManagedObjectContext) async throws -> [NSManagedObjectID] {
        try await context.perform {
            let categories = (0..<Self.categoriesCount).map { _ in
                let category = Category(context: context)
                category.id = UUID()
                category.title = Self.randomTitle()
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
        var inserted = 0
        while inserted < count {
            let size = min(batchSize, count - inserted)
            try await context.perform {
                try autoreleasepool {
                    let categories = categoryIDs.compactMap { context.object(with: $0) as? Category }
                    for _ in 0..<size {
                        let item = Item(context: context)
                        item.id = UUID()
                        item.title = Self.randomTitle()
                        item.value = Self.randomValue()
                        item.createdAt = Self.randomDate()
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
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type))
        try context.execute(NSBatchDeleteRequest(fetchRequest: request))
    }

    static func randomTitle() -> String {
        String((0..<titleLength).compactMap { _ in titleLetters.randomElement() })
    }

    static func randomValue() -> Int64 {
        Int64.random(in: valueRange)
    }

    static func randomDate() -> Date {
        Date(timeIntervalSinceNow: -TimeInterval.random(in: 0...secondsInYear))
    }
}
