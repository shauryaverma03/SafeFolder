//
//  SplashViewController.swift
//  SafeFolder
//
//  Animated splash screen showing app logo with smooth entrance animation.
//

import UIKit

/// Animated splash screen with logo and app name
final class SplashViewController: UIViewController {
    
    /// Callback when splash animation completes
    var onComplete: (() -> Void)?
    
    // MARK: - UI Components
    
    /// Shield + lock icon container
    private let logoContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Shield background
    private let shieldView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "shield.fill")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = AppTheme.accentColor
        return iv
    }()
    
    /// Folder icon on shield
    private let folderIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "folder.fill")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()
    
    /// App name label
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Safe Folder"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = AppTheme.primaryText
        label.textAlignment = .center
        return label
    }()
    
    /// Tagline label
    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Your files. Secured."
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        return label
    }()
    
    /// Gradient layer for shield
    private var shieldGradientLayer: CAGradientLayer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateSplash()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppTheme.primaryBackground
        
        view.addSubview(logoContainer)
        logoContainer.addSubview(shieldView)
        logoContainer.addSubview(folderIcon)
        view.addSubview(titleLabel)
        view.addSubview(taglineLabel)
        
        NSLayoutConstraint.activate([
            // Logo container centered
            logoContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            logoContainer.widthAnchor.constraint(equalToConstant: 120),
            logoContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Shield fills container
            shieldView.topAnchor.constraint(equalTo: logoContainer.topAnchor),
            shieldView.leadingAnchor.constraint(equalTo: logoContainer.leadingAnchor),
            shieldView.trailingAnchor.constraint(equalTo: logoContainer.trailingAnchor),
            shieldView.bottomAnchor.constraint(equalTo: logoContainer.bottomAnchor),
            
            // Folder icon centered on shield
            folderIcon.centerXAnchor.constraint(equalTo: shieldView.centerXAnchor),
            folderIcon.centerYAnchor.constraint(equalTo: shieldView.centerYAnchor, constant: 8),
            folderIcon.widthAnchor.constraint(equalToConstant: 44),
            folderIcon.heightAnchor.constraint(equalToConstant: 38),
            
            // Title below logo
            titleLabel.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 28),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Tagline below title
            taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            taglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        // Start invisible for animation
        logoContainer.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        logoContainer.alpha = 0
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        taglineLabel.alpha = 0
        taglineLabel.transform = CGAffineTransform(translationX: 0, y: 20)
    }
    
    // MARK: - Animation
    
    private func animateSplash() {
        // Phase 1: Logo pops in with spring
        UIView.animate(
            withDuration: 0.7,
            delay: 0.1,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: .curveEaseOut
        ) {
            self.logoContainer.transform = .identity
            self.logoContainer.alpha = 1
        }
        
        // Phase 2: Title slides up
        UIView.animate(
            withDuration: 0.5,
            delay: 0.4,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        
        // Phase 3: Tagline slides up
        UIView.animate(
            withDuration: 0.5,
            delay: 0.6,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.taglineLabel.alpha = 1
            self.taglineLabel.transform = .identity
        }
        
        // Phase 4: Fade out and transition
        UIView.animate(
            withDuration: 0.4,
            delay: 2.0,
            options: .curveEaseIn
        ) {
            self.view.alpha = 0
        } completion: { _ in
            self.onComplete?()
        }
    }
}
