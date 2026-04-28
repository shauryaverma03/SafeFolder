//
//  CreateFolderViewController.swift
//  SafeFolder
//
//  Bottom sheet modal for creating a new folder with security options.
//

import UIKit

/// Bottom sheet for creating a new folder
final class CreateFolderViewController: UIViewController {
    
    weak var delegate: CreateFolderDelegate?
    
    // MARK: - UI Components
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Create New Folder"
        label.font = AppTheme.titleFont
        label.textColor = AppTheme.primaryText
        return label
    }()
    
    private let nameTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Folder Name"
        field.font = AppTheme.bodyFont
        field.textColor = AppTheme.primaryText
        field.backgroundColor = AppTheme.tertiaryBackground
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.rightViewMode = .always
        field.autocapitalizationType = .words
        field.returnKeyType = .done
        return field
    }()
    
    private let securityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Security"
        label.font = AppTheme.headlineFont
        label.textColor = AppTheme.primaryText
        return label
    }()
    
    private lazy var securitySegment: UISegmentedControl = {
        let seg = UISegmentedControl(items: ["Normal", "Secure"])
        seg.translatesAutoresizingMaskIntoConstraints = false
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = AppTheme.accentColor
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: AppTheme.primaryText], for: .normal)
        seg.addTarget(self, action: #selector(securityChanged), for: .valueChanged)
        return seg
    }()
    
    private let securityOptionsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.isHidden = true
        return stack
    }()
    
    private lazy var authTypeSegment: UISegmentedControl = {
        let items: [String]
        if BiometricManager.shared.isBiometricAvailable {
            items = ["Password", BiometricManager.shared.availableBiometricType.displayName]
        } else {
            items = ["Password"]
        }
        let seg = UISegmentedControl(items: items)
        seg.translatesAutoresizingMaskIntoConstraints = false
        seg.selectedSegmentIndex = 0
        seg.addTarget(self, action: #selector(authTypeChanged), for: .valueChanged)
        return seg
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Password"
        field.isSecureTextEntry = true
        field.font = AppTheme.bodyFont
        field.textColor = AppTheme.primaryText
        field.backgroundColor = AppTheme.tertiaryBackground
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.rightViewMode = .always
        return field
    }()
    
    private let confirmPasswordField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Confirm Password"
        field.isSecureTextEntry = true
        field.font = AppTheme.bodyFont
        field.textColor = AppTheme.primaryText
        field.backgroundColor = AppTheme.tertiaryBackground
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.rightViewMode = .always
        return field
    }()
    
    private let passwordStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppTheme.captionFont
        label.textColor = AppTheme.errorColor
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Create Folder", for: .normal)
        button.titleLabel?.font = AppTheme.headlineFont
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AppTheme.accentColor
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        nameTextField.delegate = self
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppTheme.primaryBackground
        
        passwordStack.addArrangedSubview(passwordField)
        passwordStack.addArrangedSubview(confirmPasswordField)
        
        securityOptionsStack.addArrangedSubview(authTypeSegment)
        securityOptionsStack.addArrangedSubview(passwordStack)
        
        let mainStack = UIStackView(arrangedSubviews: [
            titleLabel, nameTextField, securityLabel, securitySegment,
            securityOptionsStack, errorLabel, createButton
        ])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.setCustomSpacing(24, after: titleLabel)
        mainStack.setCustomSpacing(24, after: securityOptionsStack)
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordField.heightAnchor.constraint(equalToConstant: 50),
            confirmPasswordField.heightAnchor.constraint(equalToConstant: 50),
            createButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    // MARK: - Actions
    
    @objc private func securityChanged() {
        let isSecure = securitySegment.selectedSegmentIndex == 1
        UIView.animate(withDuration: 0.3) {
            self.securityOptionsStack.isHidden = !isSecure
            self.securityOptionsStack.alpha = isSecure ? 1 : 0
        }
        if isSecure { authTypeChanged() }
        errorLabel.isHidden = true
    }
    
    @objc private func authTypeChanged() {
        let isPassword = authTypeSegment.selectedSegmentIndex == 0
        UIView.animate(withDuration: 0.2) {
            self.passwordStack.isHidden = !isPassword
            self.passwordStack.alpha = isPassword ? 1 : 0
        }
        errorLabel.isHidden = true
    }
    
    @objc private func createTapped() {
        errorLabel.isHidden = true
        
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            showValidationError("Please enter a folder name.")
            return
        }
        
        let isSecure = securitySegment.selectedSegmentIndex == 1
        var authType: AuthType = .none
        var password: String? = nil
        
        if isSecure {
            if authTypeSegment.selectedSegmentIndex == 0 {
                // Password
                authType = .password
                let pw = passwordField.text ?? ""
                let confirm = confirmPasswordField.text ?? ""
                guard !pw.isEmpty else { showValidationError("Password cannot be empty."); return }
                guard pw.count >= 4 else { showValidationError("Password must be at least 4 characters."); return }
                guard pw == confirm else { showValidationError("Passwords do not match."); return }
                password = pw
            } else {
                // Biometric
                authType = .biometric
                if !BiometricManager.shared.isBiometricAvailable {
                    showValidationError("Biometric authentication is not available. Please use password instead.")
                    return
                }
            }
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        delegate?.didCreateFolder(name: name, isSecure: isSecure, authType: authType, password: password)
        dismiss(animated: true)
    }
    
    private func showValidationError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        // Shake animation
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -3, 3, 0]
        errorLabel.layer.add(animation, forKey: "shake")
    }
}

// MARK: - UITextFieldDelegate

extension CreateFolderViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
