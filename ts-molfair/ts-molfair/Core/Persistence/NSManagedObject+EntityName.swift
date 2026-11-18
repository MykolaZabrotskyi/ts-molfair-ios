//
//  NSManagedObject+EntityName.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import CoreData

extension NSManagedObject {

    /// Entity names in the model match the class names, so this is the single place that knows it.
    static var entityName: String {
        String(describing: self)
    }
}
