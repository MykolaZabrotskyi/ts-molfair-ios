//
//  ItemsModule.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import UIKit

enum ItemsModule {

    // MARK: - Internal Methods

    @MainActor
    static func build() -> UIViewController {
        let persistence = PersistenceController()
        let repository = CoreDataItemsRepository(persistence: persistence)
        let presenter = ItemsPresenter(repository: repository)
        let viewController = ItemsViewController(presenter: presenter)
        presenter.view = viewController
        return viewController
    }
}
