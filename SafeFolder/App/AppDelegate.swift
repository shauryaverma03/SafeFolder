//
//  AppDelegate.swift
//  SafeFolder
//
//  Production-grade secure file manager application.
//  Architecture: MVVM with UIKit (Programmatic UI)
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    /// Tracks whether a secure folder is currently open
    private var isSecureFolderOpen = false
    
    /// Privacy overlay to hide content when app enters background
    private var privacyOverlay: UIView?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Create main window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Set up root navigation controller with folder list
        let folderListVC = FolderListViewController()
        let navigationController = UINavigationController(rootViewController: folderListVC)
        
        // Configure navigation bar appearance globally
        configureNavigationBarAppearance()
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // Register for app lifecycle notifications
        registerLifecycleObservers()
        
        return true
    }
    
    // MARK: - Navigation Bar Appearance
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppTheme.primaryBackground
        appearance.titleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: AppTheme.primaryText,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = AppTheme.accentColor
        UINavigationBar.appearance().prefersLargeTitles = true
    }
    
    // MARK: - Lifecycle Observers
    
    private func registerLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Listen for secure folder open/close events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(secureFolderDidOpen),
            name: .secureFolderDidOpen,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(secureFolderDidClose),
            name: .secureFolderDidClose,
            object: nil
        )
    }
    
    // MARK: - Background/Foreground Handling
    
    @objc private func appWillResignActive() {
        // Show privacy overlay immediately when app is about to lose focus
        showPrivacyOverlay()
    }
    
    @objc private func appDidBecomeActive() {
        // Remove privacy overlay when app becomes active
        // (re-auth is handled separately)
        removePrivacyOverlay()
    }
    
    @objc private func appDidEnterBackground() {
        if isSecureFolderOpen {
            // Post notification to lock the secure folder
            NotificationCenter.default.post(name: .shouldLockSecureFolder, object: nil)
        }
    }
    
    @objc private func appWillEnterForeground() {
        if isSecureFolderOpen {
            // Post notification requiring re-authentication
            NotificationCenter.default.post(name: .requireReauthentication, object: nil)
        }
    }
    
    @objc private func secureFolderDidOpen() {
        isSecureFolderOpen = true
    }
    
    @objc private func secureFolderDidClose() {
        isSecureFolderOpen = false
    }
    
    // MARK: - Privacy Overlay
    
    private func showPrivacyOverlay() {
        guard privacyOverlay == nil, let window = window else { return }
        
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = AppTheme.primaryBackground
        overlay.tag = 999
        
        // Add blur effect
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = overlay.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.addSubview(blurView)
        
        // Add lock icon
        let lockImageView = UIImageView()
        lockImageView.image = UIImage(systemName: "lock.shield.fill")
        lockImageView.tintColor = AppTheme.accentColor
        lockImageView.contentMode = .scaleAspectFit
        lockImageView.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(lockImageView)
        
        // Add app name label
        let label = UILabel()
        label.text = "Safe Folder"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = AppTheme.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(label)
        
        NSLayoutConstraint.activate([
            lockImageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            lockImageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -30),
            lockImageView.widthAnchor.constraint(equalToConstant: 60),
            lockImageView.heightAnchor.constraint(equalToConstant: 60),
            
            label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            label.topAnchor.constraint(equalTo: lockImageView.bottomAnchor, constant: 16)
        ])
        
        window.addSubview(overlay)
        privacyOverlay = overlay
    }
    
    private func removePrivacyOverlay() {
        UIView.animate(withDuration: 0.3, animations: {
            self.privacyOverlay?.alpha = 0
        }, completion: { _ in
            self.privacyOverlay?.removeFromSuperview()
            self.privacyOverlay = nil
        })
    }
}

// MARK: - Custom Notification Names

extension Notification.Name {
    static let secureFolderDidOpen = Notification.Name("secureFolderDidOpen")
    static let secureFolderDidClose = Notification.Name("secureFolderDidClose")
    static let shouldLockSecureFolder = Notification.Name("shouldLockSecureFolder")
    static let requireReauthentication = Notification.Name("requireReauthentication")
}
