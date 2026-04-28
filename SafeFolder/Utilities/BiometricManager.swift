//
//  BiometricManager.swift
//  SafeFolder
//
//  Handles Face ID and Touch ID authentication using LocalAuthentication.
//  Provides availability checks and graceful fallback handling.
//

import Foundation
import LocalAuthentication

/// Biometric authentication type available on the device
enum BiometricType {
    case none
    case touchID
    case faceID
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "lock.fill"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        }
    }
}

/// Error types for biometric authentication
enum BiometricError: Error, LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case systemCancel
    case passcodeNotSet
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled."
        case .systemCancel:
            return "Authentication was cancelled by the system."
        case .passcodeNotSet:
            return "Device passcode is not set. Please set a passcode in Settings."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

/// Manages biometric authentication (Face ID / Touch ID)
final class BiometricManager {
    
    // MARK: - Singleton
    
    static let shared = BiometricManager()
    private init() {}
    
    // MARK: - Availability
    
    /// Returns the type of biometric available on the device
    var availableBiometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .faceID // Treat opticID like faceID for display purposes
        @unknown default:
            return .none
        }
    }
    
    /// Whether any biometric authentication is available
    var isBiometricAvailable: Bool {
        return availableBiometricType != .none
    }
    
    /// Detailed availability check with error information
    func checkAvailability() -> Result<BiometricType, BiometricError> {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotAvailable:
                    return .failure(.notAvailable)
                case .biometryNotEnrolled:
                    return .failure(.notEnrolled)
                case .passcodeNotSet:
                    return .failure(.passcodeNotSet)
                default:
                    return .failure(.unknown(laError))
                }
            }
            return .failure(.notAvailable)
        }
        
        return .success(availableBiometricType)
    }
    
    // MARK: - Authentication
    
    /// Authenticates the user with biometrics
    /// - Parameters:
    ///   - reason: The reason string displayed to the user
    ///   - completion: Completion handler with success/failure result
    func authenticate(
        reason: String = "Authenticate to access your secure folder",
        completion: @escaping (Result<Void, BiometricError>) -> Void
    ) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "" // Hide "Enter Password" fallback
        
        var error: NSError?
        
        // Check if biometrics can be evaluated
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                if let laError = error as? LAError {
                    switch laError.code {
                    case .biometryNotAvailable:
                        completion(.failure(.notAvailable))
                    case .biometryNotEnrolled:
                        completion(.failure(.notEnrolled))
                    case .passcodeNotSet:
                        completion(.failure(.passcodeNotSet))
                    default:
                        completion(.failure(.unknown(laError)))
                    }
                } else {
                    completion(.failure(.notAvailable))
                }
            }
            return
        }
        
        // Perform biometric evaluation
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else if let laError = error as? LAError {
                    switch laError.code {
                    case .userCancel:
                        completion(.failure(.userCancelled))
                    case .systemCancel:
                        completion(.failure(.systemCancel))
                    case .authenticationFailed:
                        completion(.failure(.authenticationFailed))
                    default:
                        completion(.failure(.unknown(laError)))
                    }
                } else {
                    completion(.failure(.authenticationFailed))
                }
            }
        }
    }
}
