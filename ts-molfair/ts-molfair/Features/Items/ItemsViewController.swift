//
//  ItemsViewController.swift
//  ts-molfair
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import SnapKit
import UIKit

@MainActor
protocol ItemsViewControllerProtocol: AnyObject {
    func render(with viewState: ItemsViewState)
}

@MainActor
final class ItemsViewController: UIViewController {

    // MARK: - Properties

    var presenter: ItemsPresenterProtocol?

    private static let cellIdentifier = "ItemCell"

    private var rows: [ItemRow] = []

    private let generateButton = UIButton(configuration: .filled())
    private let loadButton = UIButton(configuration: .tinted())
    private let countLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let tableView = UITableView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureButtons()
        configureCountLabel()
        configureActivityIndicator()
        configureTableView()
        layoutSubviews()
        presenter?.perform(with: .onLoad)
    }
}

// MARK: - ItemsViewControllerProtocol

extension ItemsViewController: ItemsViewControllerProtocol {

    func render(with viewState: ItemsViewState) {
        renderTexts(viewState.texts)

        switch viewState.kind {
        case .loading:
            setLoading(true)

        case .loaded(let rows, let countText):
            setLoading(false)
            self.rows = rows
            countLabel.text = countText
            tableView.reloadData()

        case .error(let message):
            setLoading(false)
            showError(message, texts: viewState.texts)
        }
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
        generateButton.addAction(UIAction { [weak self] _ in
            self?.presenter?.perform(with: .onGenerateTapped)
        }, for: .touchUpInside)

        loadButton.addAction(UIAction { [weak self] _ in
            self?.presenter?.perform(with: .onLoadTapped)
        }, for: .touchUpInside)
    }

    func configureCountLabel() {
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

    func renderTexts(_ texts: ItemsViewState.Texts) {
        title = texts.navigationTitle
        generateButton.configuration?.title = texts.generateButtonTitle
        loadButton.configuration?.title = texts.loadButtonTitle
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        generateButton.isEnabled = !isLoading
        loadButton.isEnabled = !isLoading
    }

    func showError(_ message: String, texts: ItemsViewState.Texts) {
        let alert = UIAlertController(title: texts.errorTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: texts.errorOkAction, style: .default))
        present(alert, animated: true)
    }
}
