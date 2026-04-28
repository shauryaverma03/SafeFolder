//
//  FileStorageManager.swift
//  SafeFolder
//
//  Manages all file system operations: creating/deleting folder directories,
//  saving/retrieving files, and managing the app's Documents directory structure.
//

import Foundation
import UIKit

/// Manages file storage using FileManager within the app's Documents directory
final class FileStorageManager {
    
    // MARK: - Singleton
    
    static let shared = FileStorageManager()
    private init() {
        createRootDirectoryIfNeeded()
    }
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    
    /// Root directory name for all Safe Folder data
    private let rootDirectoryName = "SafeFolderData"
    
    /// Base URL for the app's Documents directory
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Root URL for all folder storage
    private var rootURL: URL {
        documentsURL.appendingPathComponent(rootDirectoryName)
    }
    
    // MARK: - Directory Management
    
    /// Creates the root storage directory if it doesn't exist
    private func createRootDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: rootURL.path) {
            do {
                try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
                print("[FileStorageManager] Root directory created at: \(rootURL.path)")
            } catch {
                print("[FileStorageManager] Failed to create root directory: \(error)")
            }
        }
    }
    
    /// Returns the URL for a specific folder's directory
    func folderURL(for folder: Folder) -> URL {
        return rootURL.appendingPathComponent(folder.directoryName)
    }
    
    /// Creates a directory for a new folder
    /// - Parameter folder: The folder to create a directory for
    /// - Returns: Whether the directory was created successfully
    @discardableResult
    func createFolderDirectory(for folder: Folder) -> Bool {
        let url = folderURL(for: folder)
        
        if fileManager.fileExists(atPath: url.path) {
            return true // Directory already exists
        }
        
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            print("[FileStorageManager] Created folder directory: \(folder.name)")
            return true
        } catch {
            print("[FileStorageManager] Failed to create folder directory: \(error)")
            return false
        }
    }
    
    /// Deletes a folder's directory and all its contents
    /// - Parameter folder: The folder to delete
    /// - Returns: Whether the deletion was successful
    @discardableResult
    func deleteFolderDirectory(for folder: Folder) -> Bool {
        let url = folderURL(for: folder)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return true // Already deleted
        }
        
        do {
            try fileManager.removeItem(at: url)
            print("[FileStorageManager] Deleted folder directory: \(folder.name)")
            return true
        } catch {
            print("[FileStorageManager] Failed to delete folder directory: \(error)")
            return false
        }
    }
    
    // MARK: - File Operations
    
    /// Saves a file to a folder's directory
    /// - Parameters:
    ///   - data: The file data to save
    ///   - fileName: The storage name for the file
    ///   - folder: The destination folder
    /// - Returns: The URL of the saved file, or nil on failure
    @discardableResult
    func saveFile(data: Data, fileName: String, to folder: Folder) -> URL? {
        let folderDir = folderURL(for: folder)
        
        // Ensure the folder directory exists
        createFolderDirectory(for: folder)
        
        let fileURL = folderDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            print("[FileStorageManager] Saved file: \(fileName) to \(folder.name)")
            return fileURL
        } catch {
            print("[FileStorageManager] Failed to save file: \(error)")
            return nil
        }
    }
    
    /// Retrieves a file's data from a folder
    /// - Parameters:
    ///   - fileName: The storage name of the file
    ///   - folder: The folder containing the file
    /// - Returns: The file data, or nil if not found
    func retrieveFileData(fileName: String, from folder: Folder) -> Data? {
        let fileURL = folderURL(for: folder).appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try? Data(contentsOf: fileURL)
    }
    
    /// Returns the URL for a specific file in a folder
    func fileURL(fileName: String, in folder: Folder) -> URL {
        return folderURL(for: folder).appendingPathComponent(fileName)
    }
    
    /// Deletes a specific file from a folder
    /// - Parameters:
    ///   - fileName: The storage name of the file to delete
    ///   - folder: The folder containing the file
    /// - Returns: Whether the deletion was successful
    @discardableResult
    func deleteFile(fileName: String, from folder: Folder) -> Bool {
        let fileURL = folderURL(for: folder).appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return true
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("[FileStorageManager] Deleted file: \(fileName)")
            return true
        } catch {
            print("[FileStorageManager] Failed to delete file: \(error)")
            return false
        }
    }
    
    /// Gets the size of a file in bytes
    /// - Parameters:
    ///   - fileName: The storage name of the file
    ///   - folder: The folder containing the file
    /// - Returns: File size in bytes, or 0 if not found
    func fileSize(fileName: String, in folder: Folder) -> Int64 {
        let fileURL = folderURL(for: folder).appendingPathComponent(fileName)
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        
        return size
    }
    
    /// Counts the number of files in a folder's directory
    func fileCount(for folder: Folder) -> Int {
        let url = folderURL(for: folder)
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: url.path) else {
            return 0
        }
        
        return contents.count
    }
    
    /// Generates a unique file name if a file with the same name already exists
    /// - Parameters:
    ///   - originalName: The original file name
    ///   - folder: The target folder
    /// - Returns: A unique file name (with suffix if needed)
    func uniqueFileName(_ originalName: String, in folder: Folder) -> String {
        let url = folderURL(for: folder)
        let fileURL = url.appendingPathComponent(originalName)
        
        if !fileManager.fileExists(atPath: fileURL.path) {
            return originalName
        }
        
        // Split name and extension
        let nameWithoutExt = (originalName as NSString).deletingPathExtension
        let ext = (originalName as NSString).pathExtension
        
        var counter = 1
        var newName: String
        
        repeat {
            newName = ext.isEmpty ? "\(nameWithoutExt)_\(counter)" : "\(nameWithoutExt)_\(counter).\(ext)"
            counter += 1
        } while fileManager.fileExists(atPath: url.appendingPathComponent(newName).path)
        
        return newName
    }
    
    // MARK: - Storage Info
    
    /// Returns the available disk space in bytes
    var availableDiskSpace: Int64 {
        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: documentsURL.path),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return 0
        }
        return freeSpace
    }
    
    /// Checks if there's enough storage space for a given data size
    func hasEnoughSpace(for dataSize: Int64) -> Bool {
        return availableDiskSpace > dataSize + (10 * 1024 * 1024) // Keep 10MB buffer
    }
    
    /// Creates a thumbnail image for an image file
    func createThumbnail(for fileItem: FileItem, in folder: Folder, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        guard fileItem.canShowThumbnail else { return nil }
        
        let url = fileURL(fileName: fileItem.storageName, in: folder)
        
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Generate thumbnail
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
