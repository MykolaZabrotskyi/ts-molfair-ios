//
//  ItemCategory.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData

@objc(ItemCategory)
final class ItemCategory: NSManagedObject {

    // MARK: - Properties

    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var items: Set<Item>
}
