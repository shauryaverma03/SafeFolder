//
//  HashingUtility.swift
//  SafeFolder
//
//  Provides SHA-256 hashing for password security.
//  Uses CryptoKit (iOS 13+) for cryptographic operations.
//

import Foundation
import CryptoKit

/// Utility for cryptographic hashing operations
struct HashingUtility {
    
    /// Computes the SHA-256 hash of the input string
    /// - Parameter input: The string to hash
    /// - Returns: Hex-encoded SHA-256 hash string
    static func sha256(_ input: String) -> String {
        guard let data = input.data(using: .utf8) else {
            fatalError("[HashingUtility] Failed to convert string to data")
        }
        
        let hash = SHA256.hash(data: data)
        
        // Convert to hex string
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verifies that a plain-text input matches a given hash
    /// - Parameters:
    ///   - input: Plain-text string to verify
    ///   - hash: Expected SHA-256 hash
    /// - Returns: Whether the input produces the expected hash
    static func verify(_ input: String, against hash: String) -> Bool {
        return sha256(input) == hash
    }
}
