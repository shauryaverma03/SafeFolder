//
//  FolderDetailViewController.swift
//  SafeFolder
//
//  Shows files inside a folder with grid layout, add options, and auto-lock.
//

import UIKit
import PhotosUI
import QuickLook

/// Displays files inside a folder with grid layout
final class FolderDetailViewController: UIViewController {
    
    private let viewModel: FolderDetailViewModel
    private var hasAnimatedCells = false
    
    // MARK: - Auto-lock Toast
    
    private let countdownToast: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = AppTheme.warningColor
        label.layer.cornerRadius = 20
        label.clipsToBounds = true
        label.alpha = 0
        return label
    }()
    
    // MARK: - UI Components
    
    private lazy var collectionView: UICollectionView = {
        let layout = createGridLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(FileCell.self, forCellWithReuseIdentifier: FileCell.reuseIdentifier)
        cv.showsVerticalScrollIndicator = false
        cv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 100, right: 0)
        return cv
    }()
    
    private lazy var addButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        btn.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = AppTheme.accentColor
        btn.layer.cornerRadius = 28
        AppTheme.applyCardShadow(to: btn)
        btn.layer.shadowColor = AppTheme.accentColor.cgColor
        btn.layer.shadowOpacity = 0.4
        btn.addTarget(self, action: #selector(addFileTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "doc.badge.plus")
        iconView.tintColor = AppTheme.secondaryText.withAlphaComponent(0.5)
        iconView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Files Yet"
        titleLabel.font = AppTheme.titleFont
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Tap + to add photos, videos, or documents"
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
            iconView.widthAnchor.constraint(equalToConstant: 70),
            iconView.heightAnchor.constraint(equalToConstant: 70),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
        return view
    }()
    
    /// Preview item for QLPreviewController
    private var previewURL: URL?
    
    // MARK: - Init
    
    init(folder: Folder) {
        self.viewModel = FolderDetailViewModel(folder: folder)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        viewModel.delegate = self
        viewModel.unlock()
        updateEmptyState()
        registerNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.lock()
        // Notify folder list to refresh file counts
        NotificationCenter.default.post(name: .secureFolderDidClose, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Touch Handling for Auto-Lock Reset
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        viewModel.resetAutoLockTimer()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppTheme.primaryBackground
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(addButton)
        view.addSubview(countdownToast)
        
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
            
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 56),
            
            countdownToast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            countdownToast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownToast.widthAnchor.constraint(equalToConstant: 200),
            countdownToast.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    private func setupNavigationBar() {
        title = viewModel.folder.name
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let addBarBtn = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain, target: self, action: #selector(addFileTapped)
        )
        navigationItem.rightBarButtonItem = addBarBtn
    }
    
    private func createGridLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0/3.0), heightDimension: .absolute(160))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(160))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item, item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleLockNotification), name: .shouldLockSecureFolder, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReauthNotification), name: .requireReauthentication, object: nil)
    }
    
    @objc private func handleLockNotification() {
        viewModel.lock()
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func handleReauthNotification() {
        viewModel.lock()
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func addFileTapped() {
        viewModel.resetAutoLockTimer()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let sheet = UIAlertController(title: "Add File", message: "Choose a source", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.openCamera()
        })
        sheet.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.openPhotoLibrary()
        })
        sheet.addAction(UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.openDocumentPicker()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(sheet, animated: true)
    }
    
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showError("Camera is not available on this device.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    private func openPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 20
        config.filter = .any(of: [.images, .videos])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func openDocumentPicker() {
        let types: [UTType] = [.pdf, .plainText, .spreadsheet, .presentation, .data, .image, .movie]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !viewModel.isEmpty
        collectionView.isHidden = viewModel.isEmpty
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func confirmDelete(at index: Int) {
        guard let file = viewModel.file(at: index) else { return }
        let alert = UIAlertController(title: "Delete File?", message: "Delete \"\(file.fileName)\"?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            self?.viewModel.deleteFile(at: index)
        })
        present(alert, animated: true)
    }
    
    private func previewFile(at index: Int) {
        guard let url = viewModel.fileURL(at: index),
              let file = viewModel.file(at: index) else { return }
        
        viewModel.resetAutoLockTimer()
        
        if file.fileType == .image {
            // Full-screen image preview
            let imageVC = ImagePreviewViewController(imageURL: url)
            imageVC.modalPresentationStyle = .fullScreen
            present(imageVC, animated: true)
        } else {
            // QLPreviewController for docs/PDFs/videos
            previewURL = url
            let ql = QLPreviewController()
            ql.dataSource = self
            present(ql, animated: true)
        }
    }
}

// MARK: - Collection View

extension FolderDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.fileCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileCell.reuseIdentifier, for: indexPath) as? FileCell,
              let file = viewModel.file(at: indexPath.item) else {
            return UICollectionViewCell()
        }
        let thumbnail = viewModel.thumbnail(for: file)
        cell.configure(with: file, thumbnail: thumbnail)
        if !hasAnimatedCells { cell.animateAppearance(delay: Double(indexPath.item) * 0.03) }
        return cell
    }
}

extension FolderDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        previewFile(at: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self?.confirmDelete(at: indexPath.item)
            }
            return UIMenu(children: [deleteAction])
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewModel.resetAutoLockTimer()
        hasAnimatedCells = true
    }
}

// MARK: - ViewModel Delegate

extension FolderDetailViewController: FolderDetailViewModelDelegate {
    func filesDidUpdate() { hasAnimatedCells = false; collectionView.reloadData(); updateEmptyState() }
    
    func fileDidAdd(at index: Int) {
        collectionView.performBatchUpdates { collectionView.insertItems(at: [IndexPath(item: index, section: 0)]) }
        updateEmptyState()
    }
    
    func fileDidDelete(at index: Int) {
        collectionView.performBatchUpdates { collectionView.deleteItems(at: [IndexPath(item: index, section: 0)]) }
        updateEmptyState()
    }
    
    func didEncounterError(_ message: String) { showError(message) }
    
    func autoLockCountdown(_ seconds: Int) {
        countdownToast.text = "🔒 Locking in \(seconds)..."
        if countdownToast.alpha == 0 {
            UIView.animate(withDuration: 0.3) { self.countdownToast.alpha = 1 }
        }
    }
    
    func autoLockTriggered() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        UIView.animate(withDuration: 0.3) { self.countdownToast.alpha = 0 }
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - Image Picker (Camera)

extension FolderDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            viewModel.addImage(image, originalName: "Camera_\(DateFormatter.fileNameFormatter.string(from: Date())).jpg")
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPicker (Photo Library)

extension FolderDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            let provider = result.itemProvider
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    guard let image = object as? UIImage else { return }
                    DispatchQueue.main.async {
                        let name = provider.suggestedName ?? "Photo_\(DateFormatter.fileNameFormatter.string(from: Date()))"
                        self?.viewModel.addImage(image, originalName: "\(name).jpg")
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    guard let url = url else { return }
                    // Copy to temp to keep access after provider cleanup
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    try? FileManager.default.copyItem(at: url, to: tempURL)
                    DispatchQueue.main.async {
                        self?.viewModel.addVideo(from: tempURL)
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                }
            }
        }
    }
}

// MARK: - Document Picker

extension FolderDetailViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            viewModel.addFile(from: url)
        }
    }
}

// MARK: - QLPreviewController

extension FolderDetailViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { return 1 }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return (previewURL ?? URL(fileURLWithPath: "")) as QLPreviewItem
    }
}

// MARK: - Full-Screen Image Preview

/// Simple full-screen image viewer with pinch-to-zoom
final class ImagePreviewViewController: UIViewController {
    
    private let imageURL: URL
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.delegate = self
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
        
        if let data = try? Data(contentsOf: imageURL) {
            imageView.image = UIImage(data: data)
        }
        
        // Close button
        let closeBtn = UIButton(type: .system)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        closeBtn.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        closeBtn.tintColor = .white
        closeBtn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeBtn.layer.cornerRadius = 18
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeBtn)
        
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 36),
            closeBtn.heightAnchor.constraint(equalToConstant: 36),
        ])
    }
    
    @objc private func closeTapped() { dismiss(animated: true) }
}

extension ImagePreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { return imageView }
}
