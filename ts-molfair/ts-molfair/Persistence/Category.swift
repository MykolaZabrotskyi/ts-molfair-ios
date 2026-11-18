//
//  Category.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData

@objc(Category)
final class Category: NSManagedObject {

    // MARK: - Properties

    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var items: Set<Item>

    // MARK: - Internal Methods

    @nonobjc class func fetchRequest() -> NSFetchRequest<Category> {
        NSFetchRequest<Category>(entityName: "Category")
    }
}
