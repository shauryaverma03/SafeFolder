//
//  FolderListViewModel.swift
//  SafeFolder
//
//  ViewModel for the Folder List screen.
//  Manages folder CRUD operations, persistence, and security conversions.
//

import Foundation

/// Delegate protocol for FolderListViewModel state changes
protocol FolderListViewModelDelegate: AnyObject {
    func foldersDidUpdate()
    func folderDidAdd(at index: Int)
    func folderDidDelete(at index: Int)
    func folderDidUpdate(at index: Int)
    func didEncounterError(_ message: String)
}

/// ViewModel managing the list of folders and their persistence
final class FolderListViewModel {
    
    // MARK: - Properties
    
    weak var delegate: FolderListViewModelDelegate?
    
    /// All folders, sorted by creation date (newest first)
    private(set) var folders: [Folder] = []
    
    /// UserDefaults key for folder storage
    private let foldersKey = "com.safefolder.folders"
    
    /// Reference to shared managers
    private let storageManager = FileStorageManager.shared
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Initialization
    
    init() {
        loadFolders()
    }
    
    // MARK: - Public Methods
    
    /// Returns the number of folders
    var folderCount: Int {
        return folders.count
    }
    
    /// Returns whether the folder list is empty
    var isEmpty: Bool {
        return folders.isEmpty
    }
    
    /// Returns the folder at a given index
    func folder(at index: Int) -> Folder? {
        guard index >= 0 && index < folders.count else { return nil }
        return folders[index]
    }
    
    /// Creates a new folder with the specified configuration
    /// - Parameters:
    ///   - name: Folder display name
    ///   - isSecure: Whether the folder is password/biometric protected
    ///   - authType: Authentication type
    ///   - password: Optional password (for .password auth type)
    func createFolder(
        name: String,
        isSecure: Bool,
        authType: AuthType,
        password: String? = nil
    ) {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            delegate?.didEncounterError("Folder name cannot be empty.")
            return
        }
        
        // Check for duplicate names
        if folders.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            delegate?.didEncounterError("A folder with this name already exists.")
            return
        }
        
        // Create the folder model
        var folder = Folder(name: trimmedName, isSecure: isSecure, authType: authType)
        
        // Create the file system directory
        guard storageManager.createFolderDirectory(for: folder) else {
            delegate?.didEncounterError("Failed to create folder directory. Please check available storage.")
            return
        }
        
        // Save password to Keychain if password-protected
        if authType == .password, let password = password {
            guard keychainManager.savePassword(password, forFolderID: folder.id) else {
                delegate?.didEncounterError("Failed to save password securely.")
                storageManager.deleteFolderDirectory(for: folder)
                return
            }
        }
        
        // Update file count
        folder.fileCount = storageManager.fileCount(for: folder)
        
        // Add to array and persist
        folders.insert(folder, at: 0)
        saveFolders()
        
        delegate?.folderDidAdd(at: 0)
    }
    
    /// Deletes a folder and all its contents
    /// - Parameter index: Index of the folder to delete
    func deleteFolder(at index: Int) {
        guard index >= 0 && index < folders.count else { return }
        
        let folder = folders[index]
        
        // Delete from file system
        storageManager.deleteFolderDirectory(for: folder)
        
        // Delete password from Keychain if secure
        if folder.isSecure && folder.authType == .password {
            keychainManager.deletePassword(forFolderID: folder.id)
        }
        
        // Remove from array and persist
        folders.remove(at: index)
        saveFolders()
        
        delegate?.folderDidDelete(at: index)
    }
    
    /// Converts a normal folder to a secure folder
    /// - Parameters:
    ///   - index: Index of the folder
    ///   - authType: New authentication type
    ///   - password: Password (if authType is .password)
    func convertToSecure(at index: Int, authType: AuthType, password: String? = nil) {
        guard index >= 0 && index < folders.count else { return }
        
        var folder = folders[index]
        
        // Save password if needed
        if authType == .password, let password = password {
            guard keychainManager.savePassword(password, forFolderID: folder.id) else {
                delegate?.didEncounterError("Failed to save password securely.")
                return
            }
        }
        
        folder.isSecure = true
        folder.authType = authType
        folder.modifiedAt = Date()
        
        folders[index] = folder
        saveFolders()
        
        delegate?.folderDidUpdate(at: index)
    }
    
    /// Converts a secure folder to a normal folder (must authenticate first)
    /// - Parameter index: Index of the folder
    func convertToNormal(at index: Int) {
        guard index >= 0 && index < folders.count else { return }
        
        var folder = folders[index]
        
        // Remove password from Keychain
        if folder.authType == .password {
            keychainManager.deletePassword(forFolderID: folder.id)
        }
        
        folder.isSecure = false
        folder.authType = .none
        folder.modifiedAt = Date()
        
        folders[index] = folder
        saveFolders()
        
        delegate?.folderDidUpdate(at: index)
    }
    
    /// Updates the file count for a specific folder
    func refreshFileCount(for folderID: UUID) {
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
        
        var folder = folders[index]
        folder.fileCount = storageManager.fileCount(for: folder)
        folders[index] = folder
        saveFolders()
        
        delegate?.folderDidUpdate(at: index)
    }
    
    /// Reloads all folder data from persistence
    func reload() {
        loadFolders()
        
        // Refresh file counts
        for i in 0..<folders.count {
            folders[i].fileCount = storageManager.fileCount(for: folders[i])
        }
        saveFolders()
        
        delegate?.foldersDidUpdate()
    }
    
    // MARK: - Persistence (UserDefaults + Codable)
    
    /// Loads folders from UserDefaults
    private func loadFolders() {
        guard let data = UserDefaults.standard.data(forKey: foldersKey) else {
            folders = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([Folder].self, from: data)
            folders = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("[FolderListViewModel] Failed to decode folders: \(error)")
            folders = []
        }
    }
    
    /// Saves folders to UserDefaults
    private func saveFolders() {
        do {
            let data = try JSONEncoder().encode(folders)
            UserDefaults.standard.set(data, forKey: foldersKey)
        } catch {
            print("[FolderListViewModel] Failed to encode folders: \(error)")
        }
    }
}
