//
//  AuthViewController.swift
//  SafeFolder
//
//  Full-screen authentication screen for secure folders.
//  Supports password entry and biometric (Face ID / Touch ID).
//

import UIKit

/// Full-screen authentication for secure folders
final class AuthViewController: UIViewController {
    
    weak var delegate: AuthViewControllerDelegate?
    
    /// Callback for inline auth (security conversion)
    var onSuccess: (() -> Void)?
    
    private let folder: Folder
    private var failedAttempts = 0
    private let maxAttempts = 5
    private var isLockedOut = false
    private var lockoutTimer: Timer?
    
    // MARK: - UI Components
    
    private let lockIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = AppTheme.accentColor
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.titleFont
        label.textColor = AppTheme.primaryText
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.subheadFont
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Enter Password"
        field.isSecureTextEntry = true
        field.font = AppTheme.bodyFont
        field.textColor = AppTheme.primaryText
        field.backgroundColor = AppTheme.tertiaryBackground
        field.layer.cornerRadius = 14
        field.textAlignment = .center
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.rightViewMode = .always
        return field
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.captionFont
        label.textColor = AppTheme.errorColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private lazy var unlockButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Unlock", for: .normal)
        btn.titleLabel?.font = AppTheme.headlineFont
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = AppTheme.accentColor
        btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(unlockTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Cancel", for: .normal)
        btn.titleLabel?.font = AppTheme.subheadFont
        btn.setTitleColor(AppTheme.secondaryText, for: .normal)
        btn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var biometricButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let bioType = BiometricManager.shared.availableBiometricType
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        btn.setImage(UIImage(systemName: bioType.iconName, withConfiguration: config), for: .normal)
        btn.tintColor = AppTheme.accentColor
        btn.addTarget(self, action: #selector(biometricTapped), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    
    private let attemptsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.smallCaptionFont
        label.textColor = AppTheme.secondaryText
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Init
    
    init(folder: Folder) {
        self.folder = folder
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureForAuthType()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if folder.authType == .biometric {
            triggerBiometric()
        } else {
            passwordField.becomeFirstResponder()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppTheme.primaryBackground
        
        view.addSubview(lockIcon)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(passwordField)
        view.addSubview(errorLabel)
        view.addSubview(attemptsLabel)
        view.addSubview(unlockButton)
        view.addSubview(biometricButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            lockIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lockIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            lockIcon.widthAnchor.constraint(equalToConstant: 64),
            lockIcon.heightAnchor.constraint(equalToConstant: 64),
            
            titleLabel.topAnchor.constraint(equalTo: lockIcon.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            passwordField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            passwordField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            passwordField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            passwordField.heightAnchor.constraint(equalToConstant: 50),
            
            errorLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 10),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            attemptsLabel.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 4),
            attemptsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            unlockButton.topAnchor.constraint(equalTo: attemptsLabel.bottomAnchor, constant: 20),
            unlockButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            unlockButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            unlockButton.heightAnchor.constraint(equalToConstant: 50),
            
            biometricButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            biometricButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            biometricButton.widthAnchor.constraint(equalToConstant: 80),
            biometricButton.heightAnchor.constraint(equalToConstant: 80),
            
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    private func configureForAuthType() {
        titleLabel.text = folder.name
        lockIcon.image = UIImage(systemName: "lock.shield.fill")
        
        switch folder.authType {
        case .password:
            subtitleLabel.text = "Enter your password to unlock"
            passwordField.isHidden = false
            unlockButton.isHidden = false
            biometricButton.isHidden = true
        case .biometric:
            let bioType = BiometricManager.shared.availableBiometricType
            subtitleLabel.text = "Use \(bioType.displayName) to unlock"
            passwordField.isHidden = true
            unlockButton.isHidden = true
            biometricButton.isHidden = false
        case .none:
            handleSuccess()
        }
    }
    
    // MARK: - Actions
    
    @objc private func unlockTapped() {
        guard !isLockedOut else {
            showError("Too many failed attempts. Please wait 30 seconds.")
            return
        }
        
        let password = passwordField.text ?? ""
        guard !password.isEmpty else {
            showError("Please enter your password.")
            return
        }
        
        if KeychainManager.shared.verifyPassword(password, forFolderID: folder.id) {
            handleSuccess()
        } else {
            handleFailure()
        }
    }
    
    @objc private func biometricTapped() {
        triggerBiometric()
    }
    
    @objc private func cancelTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if onSuccess != nil {
            // Inline auth mode — just dismiss
            dismiss(animated: true)
        } else {
            delegate?.authDidCancel()
        }
    }
    
    private func triggerBiometric() {
        BiometricManager.shared.authenticate(reason: "Unlock \"\(folder.name)\"") { [weak self] result in
            switch result {
            case .success:
                self?.handleSuccess()
            case .failure(let error):
                switch error {
                case .userCancelled:
                    break // User cancelled, do nothing
                case .notAvailable, .notEnrolled:
                    self?.showBiometricFallback(error.errorDescription ?? "Biometric unavailable")
                default:
                    self?.showError(error.errorDescription ?? "Authentication failed.")
                }
            }
        }
    }
    
    private func handleSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Animate lock icon to unlocked
        UIView.animate(withDuration: 0.3) {
            self.lockIcon.image = UIImage(systemName: "lock.open.fill")
            self.lockIcon.tintColor = AppTheme.successColor
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            if let onSuccess = self.onSuccess {
                self.dismiss(animated: true) { onSuccess() }
            } else {
                self.delegate?.authDidSucceed(for: self.folder)
            }
        }
    }
    
    private func handleFailure() {
        failedAttempts += 1
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        let remaining = maxAttempts - failedAttempts
        
        if remaining <= 0 {
            isLockedOut = true
            showError("Too many failed attempts. Locked for 30 seconds.")
            unlockButton.isEnabled = false
            unlockButton.alpha = 0.5
            passwordField.isEnabled = false
            
            lockoutTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
                self?.isLockedOut = false
                self?.failedAttempts = 0
                self?.unlockButton.isEnabled = true
                self?.unlockButton.alpha = 1.0
                self?.passwordField.isEnabled = true
                self?.errorLabel.isHidden = true
                self?.attemptsLabel.isHidden = true
            }
        } else {
            showError("Incorrect password.")
            attemptsLabel.text = "\(remaining) attempt\(remaining == 1 ? "" : "s") remaining"
            attemptsLabel.isHidden = false
        }
        
        // Shake the password field
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10, 10, -8, 8, -4, 4, 0]
        passwordField.layer.add(animation, forKey: "shake")
        passwordField.text = ""
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    private func showBiometricFallback(_ message: String) {
        let alert = UIAlertController(
            title: "Biometric Unavailable",
            message: "\(message)\n\nPlease enable biometrics in Settings > Face ID & Passcode.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.cancelTapped()
        })
        present(alert, animated: true)
    }
    
    deinit {
        lockoutTimer?.invalidate()
    }
}
