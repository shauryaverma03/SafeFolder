//
//  KeychainManager.swift
//  SafeFolder
//
//  Secure wrapper around the iOS Keychain for storing and retrieving
//  hashed passwords. Passwords are NEVER stored in plain text.
//

import Foundation
import Security

/// Manages all Keychain operations for the app.
/// Stores SHA-256 hashed passwords keyed by folder UUID.
final class KeychainManager {
    
    // MARK: - Singleton
    
    static let shared = KeychainManager()
    private init() {}
    
    // MARK: - Constants
    
    /// Service identifier for Keychain items
    private let service = "com.safefolder.passwords"
    
    // MARK: - Public Methods
    
    /// Saves a hashed password to the Keychain for a specific folder
    /// - Parameters:
    ///   - password: The plain-text password (will be hashed before storage)
    ///   - folderID: The UUID of the folder
    /// - Returns: Whether the save was successful
    @discardableResult
    func savePassword(_ password: String, forFolderID folderID: UUID) -> Bool {
        // Hash the password using SHA-256 before storing
        let hashedPassword = HashingUtility.sha256(password)
        
        guard let data = hashedPassword.data(using: .utf8) else {
            return false
        }
        
        // Delete any existing password for this folder first
        deletePassword(forFolderID: folderID)
        
        // Build the Keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: folderID.uuidString,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("[KeychainManager] Failed to save password. Status: \(status)")
        }
        
        return status == errSecSuccess
    }
    
    /// Verifies a password against the stored hash for a folder
    /// - Parameters:
    ///   - password: The plain-text password to verify
    ///   - folderID: The UUID of the folder
    /// - Returns: Whether the password matches
    func verifyPassword(_ password: String, forFolderID folderID: UUID) -> Bool {
        guard let storedHash = retrieveHash(forFolderID: folderID) else {
            return false
        }
        
        let inputHash = HashingUtility.sha256(password)
        return storedHash == inputHash
    }
    
    /// Deletes the stored password for a folder
    /// - Parameter folderID: The UUID of the folder
    /// - Returns: Whether the deletion was successful
    @discardableResult
    func deletePassword(forFolderID folderID: UUID) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: folderID.uuidString
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Updates the password for a folder
    /// - Parameters:
    ///   - newPassword: The new plain-text password
    ///   - folderID: The UUID of the folder
    /// - Returns: Whether the update was successful
    @discardableResult
    func updatePassword(_ newPassword: String, forFolderID folderID: UUID) -> Bool {
        // Simply delete and re-save
        deletePassword(forFolderID: folderID)
        return savePassword(newPassword, forFolderID: folderID)
    }
    
    /// Checks if a password exists for a folder
    /// - Parameter folderID: The UUID of the folder
    /// - Returns: Whether a password is stored
    func hasPassword(forFolderID folderID: UUID) -> Bool {
        return retrieveHash(forFolderID: folderID) != nil
    }
    
    // MARK: - Private Methods
    
    /// Retrieves the stored hash for a folder from the Keychain
    private func retrieveHash(forFolderID folderID: UUID) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: folderID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let hash = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return hash
    }
}
