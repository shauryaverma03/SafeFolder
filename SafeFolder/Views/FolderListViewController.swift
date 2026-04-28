//
//  FolderListViewController.swift
//  SafeFolder
//
//  Home screen showing all folders in a card-style collection view.
//

import UIKit

/// Delegate protocol for CreateFolderViewController
protocol CreateFolderDelegate: AnyObject {
    func didCreateFolder(name: String, isSecure: Bool, authType: AuthType, password: String?)
}

/// Delegate protocol for AuthViewController
protocol AuthViewControllerDelegate: AnyObject {
    func authDidSucceed(for folder: Folder)
    func authDidCancel()
}

/// Home screen displaying all user folders
final class FolderListViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel = FolderListViewModel()
    private var hasAnimatedCells = false
    
    // MARK: - UI Components
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(FolderCell.self, forCellWithReuseIdentifier: FolderCell.reuseIdentifier)
        cv.showsVerticalScrollIndicator = false
        cv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 100, right: 0)
        return cv
    }()
    
    private lazy var fabButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = AppTheme.accentColor
        button.layer.cornerRadius = 28
        AppTheme.applyCardShadow(to: button)
        button.layer.shadowColor = AppTheme.accentColor.cgColor
        button.layer.shadowOpacity = 0.4
        button.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "folder.badge.plus")
        iconView.tintColor = AppTheme.secondaryText.withAlphaComponent(0.5)
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Folders Yet"
        titleLabel.font = AppTheme.titleFont
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Tap + to create your first secure folder"
        subtitleLabel.font = AppTheme.bodyFont
        subtitleLabel.textColor = AppTheme.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        view.addSubview(iconView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        viewModel.delegate = self
        updateEmptyState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
        updateEmptyState()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppTheme.primaryBackground
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(fabButton)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.heightAnchor.constraint(equalToConstant: 250),
            fabButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            fabButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            fabButton.widthAnchor.constraint(equalToConstant: 56),
            fabButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }
    
    private func setupNavigationBar() {
        title = "Safe Folder"
        navigationController?.navigationBar.prefersLargeTitles = true
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain, target: self, action: #selector(fabTapped)
        )
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(180))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(180))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    // MARK: - Actions
    
    @objc private func fabTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let createVC = CreateFolderViewController()
        createVC.delegate = self
        if let sheet = createVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(createVC, animated: true)
    }
    
    private func openFolder(_ folder: Folder) {
        if folder.isSecure {
            let authVC = AuthViewController(folder: folder)
            authVC.delegate = self
            authVC.modalPresentationStyle = .fullScreen
            present(authVC, animated: true)
        } else {
            navigateToFolder(folder)
        }
    }
    
    private func navigateToFolder(_ folder: Folder) {
        let detailVC = FolderDetailViewController(folder: folder)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !viewModel.isEmpty
        collectionView.isHidden = viewModel.isEmpty
    }
    
    private func confirmDelete(at index: Int) {
        guard let folder = viewModel.folder(at: index) else { return }
        
        if folder.isSecure {
            // Require authentication before deleting a secure folder
            authenticateBeforeDeleteFolder(folder: folder, at: index)
        } else {
            showFolderDeleteConfirmation(folder: folder, at: index)
        }
    }
    
    /// Shows the final delete confirmation alert
    private func showFolderDeleteConfirmation(folder: Folder, at index: Int) {
        let alert = UIAlertController(
            title: "Delete Folder?",
            message: "Delete \"\(folder.name)\" and all its contents? This cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            self?.viewModel.deleteFolder(at: index)
        })
        present(alert, animated: true)
    }
    
    /// Requires authentication before allowing a secure folder to be deleted
    private func authenticateBeforeDeleteFolder(folder: Folder, at index: Int) {
        if folder.authType == .biometric {
            // Face ID / Touch ID
            BiometricManager.shared.authenticate(reason: "Authenticate to delete \"\(folder.name)\"") { [weak self] result in
                switch result {
                case .success:
                    self?.showFolderDeleteConfirmation(folder: folder, at: index)
                case .failure(let error):
                    if case .userCancelled = error { return }
                    self?.showError(error.localizedDescription)
                }
            }
        } else if folder.authType == .password {
            // Password check
            let alert = UIAlertController(
                title: "Authenticate",
                message: "Enter password to delete \"\(folder.name)\"",
                preferredStyle: .alert
            )
            alert.addTextField { field in
                field.placeholder = "Password"
                field.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Verify", style: .default) { [weak self] _ in
                let enteredPassword = alert.textFields?.first?.text ?? ""
                if KeychainManager.shared.verifyPassword(enteredPassword, forFolderID: folder.id) {
                    self?.showFolderDeleteConfirmation(folder: folder, at: index)
                } else {
                    self?.showError("Incorrect password. Cannot delete folder.")
                }
            })
            present(alert, animated: true)
        } else {
            showFolderDeleteConfirmation(folder: folder, at: index)
        }
    }
    
    private func showConversionOptions(at index: Int) {
        guard let folder = viewModel.folder(at: index) else { return }
        if folder.isSecure {
            let authVC = AuthViewController(folder: folder)
            authVC.onSuccess = { [weak self] in
                self?.viewModel.convertToNormal(at: index)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            authVC.modalPresentationStyle = .fullScreen
            present(authVC, animated: true)
        } else {
            let alert = UIAlertController(title: "Add Security", message: "Choose protection type", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Password", style: .default) { [weak self] _ in
                self?.showPasswordSetup(for: index)
            })
            if BiometricManager.shared.isBiometricAvailable {
                let name = BiometricManager.shared.availableBiometricType.displayName
                alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                    self?.viewModel.convertToSecure(at: index, authType: .biometric)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                })
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }
    
    private func showPasswordSetup(for index: Int) {
        let alert = UIAlertController(title: "Set Password", message: "Enter a password to protect this folder", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Password"; $0.isSecureTextEntry = true }
        alert.addTextField { $0.placeholder = "Confirm Password"; $0.isSecureTextEntry = true }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Set", style: .default) { [weak self] _ in
            let pw = alert.textFields?[0].text ?? ""
            let confirm = alert.textFields?[1].text ?? ""
            guard !pw.isEmpty else { self?.showError("Password cannot be empty."); return }
            guard pw.count >= 4 else { self?.showError("Password must be at least 4 characters."); return }
            guard pw == confirm else { self?.showError("Passwords do not match."); return }
            self?.viewModel.convertToSecure(at: index, authType: .password, password: pw)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
        present(alert, animated: true)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate

extension FolderListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.folderCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCell.reuseIdentifier, for: indexPath) as? FolderCell,
              let folder = viewModel.folder(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        cell.configure(with: folder)
        if !hasAnimatedCells { cell.animateAppearance(delay: Double(indexPath.item) * 0.05) }
        return cell
    }
}

extension FolderListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let folder = viewModel.folder(at: indexPath.item) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        openFolder(folder)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let folder = viewModel.folder(at: indexPath.item) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            var actions: [UIAction] = []
            if folder.isSecure {
                actions.append(UIAction(title: "Remove Security", image: UIImage(systemName: "lock.open"), attributes: .destructive) { _ in
                    self?.showConversionOptions(at: indexPath.item)
                })
            } else {
                actions.append(UIAction(title: "Add Security", image: UIImage(systemName: "lock.shield")) { _ in
                    self?.showConversionOptions(at: indexPath.item)
                })
            }
            actions.append(UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self?.confirmDelete(at: indexPath.item)
            })
            return UIMenu(title: folder.name, children: actions)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { hasAnimatedCells = true }
}

// MARK: - ViewModel Delegate

extension FolderListViewController: FolderListViewModelDelegate {
    func foldersDidUpdate() { hasAnimatedCells = false; collectionView.reloadData(); updateEmptyState() }
    func folderDidAdd(at index: Int) {
        collectionView.performBatchUpdates { collectionView.insertItems(at: [IndexPath(item: index, section: 0)]) }
        updateEmptyState()
    }
    func folderDidDelete(at index: Int) {
        collectionView.performBatchUpdates { collectionView.deleteItems(at: [IndexPath(item: index, section: 0)]) }
        updateEmptyState()
    }
    func folderDidUpdate(at index: Int) { collectionView.reloadItems(at: [IndexPath(item: index, section: 0)]) }
    func didEncounterError(_ message: String) { showError(message) }
}

// MARK: - CreateFolderDelegate & AuthDelegate

extension FolderListViewController: CreateFolderDelegate {
    func didCreateFolder(name: String, isSecure: Bool, authType: AuthType, password: String?) {
        viewModel.createFolder(name: name, isSecure: isSecure, authType: authType, password: password)
    }
}

extension FolderListViewController: AuthViewControllerDelegate {
    func authDidSucceed(for folder: Folder) {
        dismiss(animated: true) { [weak self] in self?.navigateToFolder(folder) }
    }
    func authDidCancel() { dismiss(animated: true) }
}
