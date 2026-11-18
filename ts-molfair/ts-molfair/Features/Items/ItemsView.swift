//
//  ItemsView.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

@MainActor
protocol ItemsView: AnyObject {

    // MARK: - Internal Methods

    func setLoading(_ isLoading: Bool)
    func showRows(_ rows: [ItemRow], countText: String)
    func showError(_ message: String)
}
