//
//  FileListCell.swift
//  SafeFolder
//
//  Apple Files-style horizontal list cell.
//  Small thumbnail on left, file name + date/size on right, bottom separator.
//

import UIKit

/// Apple Files-style list cell for displaying files in a row layout
final class FileListCell: UICollectionViewCell {
    
    static let reuseIdentifier = "FileListCell"
    
    // MARK: - UI Components
    
    /// Small thumbnail or icon
    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppTheme.tertiaryBackground
        iv.layer.cornerRadius = 6
        iv.layer.borderWidth = 0.5
        iv.layer.borderColor = UIColor.separator.cgColor
        return iv
    }()
    
    /// Icon overlay for non-image files
    private let fileIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = AppTheme.secondaryText
        return iv
    }()
    
    /// File name
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = AppTheme.primaryText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    /// Subtitle: date + size
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = AppTheme.secondaryText
        return label
    }()
    
    /// Bottom separator line
    private let separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.separator
        return view
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(thumbnailView)
        contentView.addSubview(fileIconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(separatorLine)
        
        NSLayoutConstraint.activate([
            // Small square thumbnail on the left
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 44),
            thumbnailView.heightAnchor.constraint(equalToConstant: 44),
            
            // Icon centered in thumbnail
            fileIconView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            fileIconView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            fileIconView.widthAnchor.constraint(equalToConstant: 22),
            fileIconView.heightAnchor.constraint(equalToConstant: 22),
            
            // File name
            nameLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            
            // Detail line
            detailLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 14),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            
            // Separator at bottom (indented to match text start)
            separatorLine.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 14),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with file: FileItem, thumbnail: UIImage? = nil) {
        nameLabel.text = file.fileName
        
        // Build detail string: "size · TYPE"
        let ext = file.fileExtension.uppercased()
        detailLabel.text = "\(file.formattedSize) · \(ext)"
        
        if file.canShowThumbnail, let thumbnail = thumbnail {
            thumbnailView.image = thumbnail
            thumbnailView.contentMode = .scaleAspectFill
            fileIconView.isHidden = true
        } else {
            thumbnailView.image = nil
            thumbnailView.backgroundColor = AppTheme.tertiaryBackground
            fileIconView.isHidden = false
            fileIconView.image = UIImage(systemName: file.fileType.iconName)
            fileIconView.tintColor = file.fileType.iconColor
        }
    }
    
    // MARK: - Animations
    
    func animateAppearance(delay: TimeInterval = 0) {
        contentView.alpha = 0
        UIView.animate(withDuration: 0.25, delay: delay, options: .curveEaseOut) {
            self.contentView.alpha = 1
        }
    }
    
    // MARK: - Highlight
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.contentView.backgroundColor = self.isHighlighted
                    ? AppTheme.tertiaryBackground
                    : .clear
            }
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailView.image = nil
        fileIconView.image = nil
        fileIconView.isHidden = false
        nameLabel.text = nil
        detailLabel.text = nil
        contentView.alpha = 1
        contentView.backgroundColor = .clear
    }
}
