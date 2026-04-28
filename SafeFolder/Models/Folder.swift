//
//  Folder.swift
//  SafeFolder
//
//  Model representing a folder with optional security settings.
//  Conforms to Codable for UserDefaults persistence.
//

import Foundation

/// Authentication type for secure folders
enum AuthType: String, Codable {
    case none       // Normal (unsecured) folder
    case password   // Custom password authentication
    case biometric  // Face ID / Touch ID authentication
}

/// Represents a folder in the app with metadata and security configuration
struct Folder: Codable, Identifiable, Equatable {
    
    /// Unique identifier for the folder
    let id: UUID
    
    /// Display name of the folder
    var name: String
    
    /// Whether the folder requires authentication to access
    var isSecure: Bool
    
    /// Type of authentication required (if secure)
    var authType: AuthType
    
    /// Date the folder was created
    let createdAt: Date
    
    /// Date the folder was last modified
    var modifiedAt: Date
    
    /// Number of files in the folder (cached for display, updated on changes)
    var fileCount: Int
    
    // MARK: - Initialization
    
    /// Creates a new folder with the given configuration
    /// - Parameters:
    ///   - name: Display name of the folder
    ///   - isSecure: Whether the folder is secured
    ///   - authType: Authentication type (defaults to .none)
    init(
        name: String,
        isSecure: Bool = false,
        authType: AuthType = .none
    ) {
        self.id = UUID()
        self.name = name
        self.isSecure = isSecure
        self.authType = authType
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.fileCount = 0
    }
    
    // MARK: - Computed Properties
    
    /// Returns the directory name used in FileManager (based on UUID)
    var directoryName: String {
        return id.uuidString
    }
    
    /// Formatted creation date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// File count display string
    var fileCountText: String {
        switch fileCount {
        case 0: return "Empty"
        case 1: return "1 file"
        default: return "\(fileCount) files"
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        return lhs.id == rhs.id
    }
}
