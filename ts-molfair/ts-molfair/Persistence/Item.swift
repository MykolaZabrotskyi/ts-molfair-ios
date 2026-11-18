//
//  Item.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData

@objc(Item)
final class Item: NSManagedObject {

    // MARK: - Properties

    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var value: Int64
    @NSManaged var createdAt: Date
    @NSManaged var category: Category?

    // MARK: - Internal Methods

    @nonobjc class func fetchRequest() -> NSFetchRequest<Item> {
        NSFetchRequest<Item>(entityName: "Item")
    }
}
