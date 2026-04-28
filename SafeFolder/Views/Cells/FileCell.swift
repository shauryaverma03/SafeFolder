//
//  FileCell.swift
//  SafeFolder
//
//  Custom UICollectionViewCell for displaying file items in a grid.
//  Shows thumbnail for images, SF Symbol icons for other file types.
//

import UIKit

/// Custom collection view cell for displaying a file in the grid
final class FileCell: UICollectionViewCell {
    
    // MARK: - Reuse Identifier
    
    static let reuseIdentifier = "FileCell"
    
    // MARK: - UI Components
    
    /// Container view for card styling
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppTheme.cardBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    /// Image view for thumbnails (images) or icons (other file types)
    private let thumbnailView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = AppTheme.tertiaryBackground
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    /// Icon view for non-image files (overlaid on thumbnailView)
    private let fileIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppTheme.accentColor
        return imageView
    }()
    
    /// File extension badge
    private let extensionBadge: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = AppTheme.accentColor
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    /// File name label
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.captionFont
        label.textColor = AppTheme.primaryText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    /// File size label
    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.smallCaptionFont
        label.textColor = AppTheme.secondaryText
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(thumbnailView)
        containerView.addSubview(fileIconView)
        containerView.addSubview(extensionBadge)
        containerView.addSubview(nameLabel)
        containerView.addSubview(sizeLabel)
        
        AppTheme.applySubtleShadow(to: containerView)
        
        NSLayoutConstraint.activate([
            // Container fills cell with padding
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            
            // Thumbnail area (square, top portion)
            thumbnailView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            thumbnailView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            thumbnailView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailView.widthAnchor),
            
            // File icon (centered in thumbnail area for non-image files)
            fileIconView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            fileIconView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            fileIconView.widthAnchor.constraint(equalToConstant: 44),
            fileIconView.heightAnchor.constraint(equalToConstant: 44),
            
            // Extension badge (bottom-right of thumbnail)
            extensionBadge.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: -4),
            extensionBadge.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -4),
            extensionBadge.heightAnchor.constraint(equalToConstant: 16),
            extensionBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
            
            // File name
            nameLabel.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            // File size
            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            sizeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            sizeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
        ])
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with a file item and optional thumbnail
    func configure(with file: FileItem, thumbnail: UIImage? = nil) {
        nameLabel.text = file.displayName
        sizeLabel.text = file.formattedSize
        
        // Extension badge
        if !file.fileExtension.isEmpty {
            extensionBadge.isHidden = false
            extensionBadge.text = " \(file.fileExtension.uppercased()) "
            extensionBadge.backgroundColor = file.fileType.iconColor
        } else {
            extensionBadge.isHidden = true
        }
        
        if file.canShowThumbnail, let thumbnail = thumbnail {
            // Show image thumbnail
            thumbnailView.image = thumbnail
            thumbnailView.contentMode = .scaleAspectFill
            fileIconView.isHidden = true
        } else {
            // Show file type icon
            thumbnailView.image = nil
            thumbnailView.backgroundColor = AppTheme.tertiaryBackground
            fileIconView.isHidden = false
            fileIconView.image = UIImage(systemName: file.fileType.iconName)
            fileIconView.tintColor = file.fileType.iconColor
        }
    }
    
    // MARK: - Animations
    
    /// Animate cell appearance
    func animateAppearance(delay: TimeInterval = 0) {
        contentView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        contentView.alpha = 0
        
        UIView.animate(
            withDuration: 0.4,
            delay: delay,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.contentView.transform = .identity
            self.contentView.alpha = 1
        }
    }
    
    /// Touch feedback
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = .identity
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = nil
        fileIconView.image = nil
        fileIconView.isHidden = false
        nameLabel.text = nil
        sizeLabel.text = nil
        extensionBadge.isHidden = true
        contentView.transform = .identity
        contentView.alpha = 1
        containerView.transform = .identity
    }
}
