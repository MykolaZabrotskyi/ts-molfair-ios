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
    private static let spacing: CGFloat = 12
    private static let navigationBarToButtonsSpacing: CGFloat = 8
    private static let buttonHeight: CGFloat = 50
    private static let buttonCornerRadius: CGFloat = 12
    private static let statusRowHeight: CGFloat = 44
    private static let estimatedRowHeight: CGFloat = 65
    private static let emptyStateImageSize = CGSize(width: 48, height: 48)

    private var rows: [ItemRow] = []

    private lazy var generateButton = makeButton(isPrimary: true)
    private lazy var loadButton = makeButton(isPrimary: false)
    private let buttonStackView = UIStackView()
    private let countLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let headerDivider = UIView()
    private let tableView = UITableView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        configureNavigationBar()
        configureButtons()
        configureStatusRow()
        configureTableView()
        layoutSubviews()
        updateButtonAxis()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.updateButtonAxis()
        }
        registerForTraitChanges([UITraitDisplayScale.self]) { (self: Self, _) in
            self.updateDividerHeight()
        }
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
            updateEmptyState(texts: viewState.texts)

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
        content.textProperties.font = .preferredFont(forTextStyle: .body)
        content.textProperties.color = .textPrimary
        content.textProperties.adjustsFontForContentSizeCategory = true
        content.secondaryText = row.id.uuidString
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
        content.secondaryTextProperties.color = .textSecondary
        content.secondaryTextProperties.adjustsFontForContentSizeCategory = true
        content.textToSecondaryTextVerticalPadding = 3
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16)
        cell.contentConfiguration = content

        var background = UIBackgroundConfiguration.listPlainCell()
        background.backgroundColor = .appBackground
        cell.backgroundConfiguration = background
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - Private Methods

private extension ItemsViewController {

    func makeButton(isPrimary: Bool) -> UIButton {
        var configuration: UIButton.Configuration = isPrimary ? .filled() : .tinted()
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = Self.buttonCornerRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .headline)
            return attributes
        }

        let button = UIButton(configuration: configuration)
        button.configurationUpdateHandler = { button in
            let isEnabled = button.isEnabled
            button.configuration?.background.backgroundColor = isEnabled ? (isPrimary ? .tintColor : .accentSoft) : .fillDisabled
            button.configuration?.baseForegroundColor = isEnabled ? (isPrimary ? .onAccent : .tintColor) : .textDisabled
        }
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Self.buttonHeight)
        }
        return button
    }

    func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.textPrimary]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.largeTitleDisplayMode = .always
    }

    func configureButtons() {
        generateButton.addAction(UIAction { [weak self] _ in
            self?.presenter?.perform(with: .onGenerateTapped)
        }, for: .touchUpInside)

        loadButton.addAction(UIAction { [weak self] _ in
            self?.presenter?.perform(with: .onLoadTapped)
        }, for: .touchUpInside)

        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = Self.spacing
        buttonStackView.addArrangedSubview(generateButton)
        buttonStackView.addArrangedSubview(loadButton)
    }

    func configureStatusRow() {
        countLabel.font = .preferredFont(forTextStyle: .headline)
        countLabel.textColor = .textPrimary
        countLabel.numberOfLines = 0
        countLabel.adjustsFontForContentSizeCategory = true

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .textSecondary

        headerDivider.backgroundColor = .rowSeparator
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.backgroundColor = .appBackground
        tableView.separatorColor = .rowSeparator
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Self.estimatedRowHeight
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
    }

    func layoutSubviews() {
        let subviews: [UIView] = [buttonStackView, countLabel, activityIndicator, headerDivider, tableView]
        subviews.forEach(view.addSubview)

        let margins = view.layoutMarginsGuide

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Self.navigationBarToButtonsSpacing)
            make.leading.trailing.equalTo(margins)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(buttonStackView.snp.bottom).offset(Self.spacing)
            make.leading.equalTo(margins)
            make.height.greaterThanOrEqualTo(Self.statusRowHeight)
            make.trailing.lessThanOrEqualTo(activityIndicator.snp.leading).offset(-Self.spacing)
        }

        activityIndicator.snp.makeConstraints { make in
            make.centerY.equalTo(countLabel)
            make.trailing.equalTo(margins)
        }

        headerDivider.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / max(traitCollection.displayScale, 1))
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerDivider.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    /// At accessibility text sizes the two buttons would not fit side by side, so they stack.
    func updateButtonAxis() {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        buttonStackView.axis = isAccessibilitySize ? .vertical : .horizontal
    }

    func updateDividerHeight() {
        headerDivider.snp.updateConstraints { make in
            make.height.equalTo(1 / max(traitCollection.displayScale, 1))
        }
    }

    func renderTexts(_ texts: ItemsViewState.Texts) {
        title = texts.navigationTitle
        generateButton.configuration?.title = texts.generateButtonTitle
        loadButton.configuration?.title = texts.loadButtonTitle
        activityIndicator.accessibilityLabel = texts.spinnerAccessibilityLabel
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

    func updateEmptyState(texts: ItemsViewState.Texts) {
        guard rows.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(named: "LaunchMark")
        configuration.imageProperties.maximumSize = Self.emptyStateImageSize
        configuration.text = texts.emptyTitle
        configuration.textProperties.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
        configuration.textProperties.color = .textPrimary
        configuration.secondaryText = texts.emptyMessage
        configuration.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        configuration.secondaryTextProperties.color = .textSecondary
        tableView.backgroundView = UIContentUnavailableView(configuration: configuration)
    }

    func showError(_ message: String, texts: ItemsViewState.Texts) {
        let alert = UIAlertController(title: texts.errorTitle, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: texts.errorOkAction, style: .default)
        alert.addAction(okAction)
        alert.preferredAction = okAction
        present(alert, animated: true)
    }
}
