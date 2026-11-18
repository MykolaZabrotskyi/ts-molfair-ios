//
//  ItemsViewController.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import SnapKit
import UIKit

@MainActor
final class ItemsViewController: UIViewController {

    // MARK: - Properties

    private static let cellIdentifier = "ItemCell"

    private let presenter: ItemsPresenter
    private var rows: [ItemRow] = []

    private let generateButton = UIButton(configuration: .filled())
    private let loadButton = UIButton(configuration: .tinted())
    private let countLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let tableView = UITableView()

    // MARK: - Init

    init(presenter: ItemsPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureButtons()
        configureCountLabel()
        configureActivityIndicator()
        configureTableView()
        layoutSubviews()
    }
}

// MARK: - ItemsView

extension ItemsViewController: ItemsView {

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        generateButton.isEnabled = !isLoading
        loadButton.isEnabled = !isLoading
    }

    func showRows(_ rows: [ItemRow], countText: String) {
        self.rows = rows
        countLabel.text = countText
        tableView.reloadData()
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ItemsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let row = rows[indexPath.row]

        var content = UIListContentConfiguration.subtitleCell()
        content.text = row.title
        content.secondaryText = row.id.uuidString
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - Private Methods

private extension ItemsViewController {

    func configureButtons() {
        generateButton.configuration?.title = "Generate"
        generateButton.addAction(UIAction { [weak self] _ in
            self?.presenter.didTapGenerate()
        }, for: .touchUpInside)

        loadButton.configuration?.title = "Load"
        loadButton.addAction(UIAction { [weak self] _ in
            self?.presenter.didTapLoad()
        }, for: .touchUpInside)
    }

    func configureCountLabel() {
        countLabel.text = "Rows: 0"
        countLabel.font = .preferredFont(forTextStyle: .headline)
        countLabel.adjustsFontForContentSizeCategory = true
    }

    func configureActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
    }

    func layoutSubviews() {
        let subviews: [UIView] = [generateButton, loadButton, countLabel, activityIndicator, tableView]
        subviews.forEach(view.addSubview)

        let guide = view.safeAreaLayoutGuide

        generateButton.snp.makeConstraints { make in
            make.top.leading.equalTo(guide).offset(16)
        }

        loadButton.snp.makeConstraints { make in
            make.top.equalTo(generateButton)
            make.leading.equalTo(generateButton.snp.trailing).offset(12)
            make.trailing.equalTo(guide).offset(-16)
            make.width.height.equalTo(generateButton)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(generateButton.snp.bottom).offset(16)
            make.leading.equalTo(guide).offset(16)
            make.trailing.lessThanOrEqualTo(activityIndicator.snp.leading).offset(-12)
        }

        activityIndicator.snp.makeConstraints { make in
            make.centerY.equalTo(countLabel)
            make.trailing.equalTo(guide).offset(-16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}
