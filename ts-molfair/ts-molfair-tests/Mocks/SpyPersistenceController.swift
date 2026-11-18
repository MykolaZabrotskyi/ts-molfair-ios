//
//  SpyPersistenceController.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData
@testable import ts_molfair

final class SpyPersistenceController {

    // MARK: - Properties

    var newBackgroundContextCallCount: Int {
        lock.withLock { recordedCallCount }
    }

    private let base: PersistenceControllerProtocol
    private let lock = NSLock()
    private var recordedCallCount = 0

    // MARK: - Init

    init(base: PersistenceControllerProtocol) {
        self.base = base
    }
}

// MARK: - PersistenceControllerProtocol

extension SpyPersistenceController: PersistenceControllerProtocol {

    func newBackgroundContext() -> NSManagedObjectContext {
        lock.withLock { recordedCallCount += 1 }
        return base.newBackgroundContext()
    }
}
