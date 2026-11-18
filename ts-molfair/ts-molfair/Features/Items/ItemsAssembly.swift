//
//  ItemsAssembly.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import UIKit

final class ItemsAssembly {

    @MainActor
    static func build() -> UIViewController {
        let persistence = PersistenceController()
        let dataGenerator = ItemsDataGenerator()
        let repository = CoreDataItemsRepository(persistence: persistence, dataGenerator: dataGenerator)
        let viewController = ItemsViewController()
        let viewStateFactory = ItemsViewStateFactory()
        let presenter = ItemsPresenter(
            viewController: viewController,
            repository: repository,
            viewStateFactory: viewStateFactory
        )

        viewController.presenter = presenter

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }
}
