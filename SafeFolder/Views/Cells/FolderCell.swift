//
//  FolderCell.swift
//  SafeFolder
//
//  Custom UICollectionViewCell for displaying folder cards.
//  Features: gradient background, shadow, lock icon, file count badge.
//

import UIKit

/// Custom collection view cell for displaying a folder card
final class FolderCell: UICollectionViewCell {
    
    // MARK: - Reuse Identifier
    
    static let reuseIdentifier = "FolderCell"
    
    // MARK: - UI Components
    
    /// Container view for card styling
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = AppTheme.cardCornerRadius
        view.clipsToBounds = false
        return view
    }()
    
    /// Inner content view (clips to bounds for rounded corners)
    private let innerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = AppTheme.cardCornerRadius
        view.clipsToBounds = true
        return view
    }()
    
    /// Folder icon view
    private let folderIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "folder.fill")
        imageView.tintColor = AppTheme.accentColor
        return imageView
    }()
    
    /// Lock icon (shown for secure folders)
    private let lockIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = AppTheme.warningColor
        return imageView
    }()
    
    /// Folder name label
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.headlineFont
        label.textColor = AppTheme.primaryText
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    /// File count label
    private let fileCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.captionFont
        label.textColor = AppTheme.secondaryText
        return label
    }()
    
    /// Date label
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.smallCaptionFont
        label.textColor = AppTheme.secondaryText
        return label
    }()
    
    /// Security badge pill
    private let securityBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.backgroundColor = AppTheme.accentColor.withAlphaComponent(0.15)
        return view
    }()
    
    /// Security badge label
    private let securityBadgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = AppTheme.accentColor
        return label
    }()
    
    /// Gradient layer for the card background
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = innerView.bounds
        
        // Update shadow path for performance
        containerView.layer.shadowPath = UIBezierPath(
            roundedRect: containerView.bounds,
            cornerRadius: AppTheme.cardCornerRadius
        ).cgPath
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateGradient()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Add container with shadow
        contentView.addSubview(containerView)
        AppTheme.applyCardShadow(to: containerView)
        
        // Add inner view (clipped for rounded corners)
        containerView.addSubview(innerView)
        
        // Add gradient background
        updateGradient()
        
        // Add subviews
        innerView.addSubview(folderIconView)
        innerView.addSubview(lockIconView)
        innerView.addSubview(nameLabel)
        innerView.addSubview(fileCountLabel)
        innerView.addSubview(dateLabel)
        innerView.addSubview(securityBadge)
        securityBadge.addSubview(securityBadgeLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container fills the cell
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Inner view matches container
            innerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            innerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            innerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            innerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Folder icon (top-left area)
            folderIconView.topAnchor.constraint(equalTo: innerView.topAnchor, constant: 16),
            folderIconView.leadingAnchor.constraint(equalTo: innerView.leadingAnchor, constant: 16),
            folderIconView.widthAnchor.constraint(equalToConstant: 36),
            folderIconView.heightAnchor.constraint(equalToConstant: 32),
            
            // Lock icon (top-right corner)
            lockIconView.topAnchor.constraint(equalTo: innerView.topAnchor, constant: 14),
            lockIconView.trailingAnchor.constraint(equalTo: innerView.trailingAnchor, constant: -14),
            lockIconView.widthAnchor.constraint(equalToConstant: 16),
            lockIconView.heightAnchor.constraint(equalToConstant: 18),
            
            // Folder name
            nameLabel.topAnchor.constraint(equalTo: folderIconView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: innerView.trailingAnchor, constant: -16),
            
            // File count
            fileCountLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            fileCountLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor, constant: 16),
            fileCountLabel.trailingAnchor.constraint(equalTo: innerView.trailingAnchor, constant: -16),
            
            // Date label (constrained to not overlap security badge)
            dateLabel.bottomAnchor.constraint(equalTo: innerView.bottomAnchor, constant: -12),
            dateLabel.leadingAnchor.constraint(equalTo: innerView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: securityBadge.leadingAnchor, constant: -4),
            
            // Security badge
            securityBadge.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            securityBadge.trailingAnchor.constraint(equalTo: innerView.trailingAnchor, constant: -12),
            securityBadge.heightAnchor.constraint(equalToConstant: 20),
            
            // Security badge label inside badge
            securityBadgeLabel.topAnchor.constraint(equalTo: securityBadge.topAnchor, constant: 3),
            securityBadgeLabel.bottomAnchor.constraint(equalTo: securityBadge.bottomAnchor, constant: -3),
            securityBadgeLabel.leadingAnchor.constraint(equalTo: securityBadge.leadingAnchor, constant: 8),
            securityBadgeLabel.trailingAnchor.constraint(equalTo: securityBadge.trailingAnchor, constant: -8),
        ])
    }
    
    private func updateGradient() {
        gradientLayer?.removeFromSuperlayer()
        
        let isDark = traitCollection.userInterfaceStyle == .dark
        let gradient = CAGradientLayer()
        
        if isDark {
            gradient.colors = [
                UIColor(red: 0.13, green: 0.14, blue: 0.24, alpha: 1.0).cgColor,
                UIColor(red: 0.10, green: 0.11, blue: 0.19, alpha: 1.0).cgColor
            ]
        } else {
            gradient.colors = [
                UIColor.white.cgColor,
                UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1.0).cgColor
            ]
        }
        
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = innerView.bounds
        gradient.cornerRadius = AppTheme.cardCornerRadius
        
        innerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with folder data
    func configure(with folder: Folder) {
        nameLabel.text = folder.name
        fileCountLabel.text = folder.fileCountText
        dateLabel.text = folder.shortFormattedDate
        
        // Lock icon visibility
        lockIconView.isHidden = !folder.isSecure
        
        // Folder icon color based on security
        folderIconView.tintColor = folder.isSecure ? AppTheme.accentGradientEnd : AppTheme.accentColor
        
        // Security badge
        if folder.isSecure {
            securityBadge.isHidden = false
            switch folder.authType {
            case .password:
                securityBadgeLabel.text = "🔑"
                securityBadge.backgroundColor = AppTheme.accentGradientEnd.withAlphaComponent(0.15)
                securityBadgeLabel.textColor = AppTheme.accentGradientEnd
            case .biometric:
                securityBadgeLabel.text = "🔐"
                securityBadge.backgroundColor = AppTheme.successColor.withAlphaComponent(0.15)
                securityBadgeLabel.textColor = AppTheme.successColor
            case .none:
                securityBadge.isHidden = true
            }
        } else {
            securityBadge.isHidden = true
        }
    }
    
    // MARK: - Animations
    
    /// Animate cell appearance with spring animation
    func animateAppearance(delay: TimeInterval = 0) {
        contentView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        contentView.alpha = 0
        
        UIView.animate(
            withDuration: 0.5,
            delay: delay,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.contentView.transform = .identity
            self.contentView.alpha = 1
        }
    }
    
    /// Animate touch feedback
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.15) {
            self.containerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.15) {
            self.containerView.transform = .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.15) {
            self.containerView.transform = .identity
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        fileCountLabel.text = nil
        dateLabel.text = nil
        lockIconView.isHidden = true
        securityBadge.isHidden = true
        contentView.transform = .identity
        contentView.alpha = 1
        containerView.transform = .identity
    }
}
