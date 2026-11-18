//
//  PersistenceController.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData

protocol PersistenceControllerProtocol {
    func newBackgroundContext() -> NSManagedObjectContext
}

final class PersistenceController {

    // MARK: - Properties

    private static let modelName = "Model"

    let container: NSPersistentContainer

    // MARK: - Init

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: PersistenceController.modelName)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent store: \(error)")
            }
        }
    }
}

// MARK: - PersistenceControllerProtocol

extension PersistenceController: PersistenceControllerProtocol {

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
