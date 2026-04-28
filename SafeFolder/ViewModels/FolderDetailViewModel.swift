//
//  FolderDetailViewModel.swift
//  SafeFolder
//
//  ViewModel for the Folder Detail screen (file management inside a folder).
//  Manages file CRUD, auto-lock timer, and authentication state.
//

import Foundation
import UIKit

/// Delegate protocol for FolderDetailViewModel state changes
protocol FolderDetailViewModelDelegate: AnyObject {
    func filesDidUpdate()
    func fileDidAdd(at index: Int)
    func fileDidDelete(at index: Int)
    func didEncounterError(_ message: String)
    func autoLockCountdown(_ seconds: Int)
    func autoLockTriggered()
}

/// ViewModel managing files within a folder and auto-lock behavior
final class FolderDetailViewModel {
    
    // MARK: - Properties
    
    weak var delegate: FolderDetailViewModelDelegate?
    
    /// The folder being viewed
    let folder: Folder
    
    /// Files in the folder, sorted by date added (newest first)
    private(set) var files: [FileItem] = []
    
    /// Whether the folder is currently unlocked
    private(set) var isUnlocked: Bool = false
    
    /// Auto-lock timer (15 seconds of inactivity)
    private var autoLockTimer: Timer?
    
    /// Countdown timer for warning display
    private var countdownTimer: Timer?
    
    /// Auto-lock timeout in seconds
    private let autoLockTimeout: TimeInterval = 15
    
    /// Countdown warning starts at 3 seconds
    private let countdownWarningStart: Int = 3
    
    /// Remaining seconds before auto-lock
    private var remainingSeconds: Int = 0
    
    /// UserDefaults key for file metadata
    private var filesKey: String {
        return "com.safefolder.files.\(folder.id.uuidString)"
    }
    
    /// Failed authentication attempt tracking
    private(set) var failedAttempts: Int = 0
    private(set) var isLockedOut: Bool = false
    private var lockoutTimer: Timer?
    private let maxAttempts = 5
    private let lockoutDuration: TimeInterval = 30
    
    /// Reference to shared managers
    private let storageManager = FileStorageManager.shared
    
    // MARK: - Initialization
    
    init(folder: Folder) {
        self.folder = folder
        self.isUnlocked = !folder.isSecure
        loadFiles()
    }
    
    deinit {
        stopAutoLockTimer()
        lockoutTimer?.invalidate()
    }
    
    // MARK: - File Count
    
    var fileCount: Int {
        return files.count
    }
    
    var isEmpty: Bool {
        return files.isEmpty
    }
    
    func file(at index: Int) -> FileItem? {
        guard index >= 0 && index < files.count else { return nil }
        return files[index]
    }
    
    // MARK: - Authentication
    
    /// Records a failed authentication attempt
    func recordFailedAttempt() {
        failedAttempts += 1
        
        if failedAttempts >= maxAttempts {
            isLockedOut = true
            
            // Start lockout timer
            lockoutTimer = Timer.scheduledTimer(withTimeInterval: lockoutDuration, repeats: false) { [weak self] _ in
                self?.isLockedOut = false
                self?.failedAttempts = 0
            }
        }
    }
    
    /// Marks the folder as unlocked and starts auto-lock timer
    func unlock() {
        isUnlocked = true
        failedAttempts = 0
        
        if folder.isSecure {
            startAutoLockTimer()
            NotificationCenter.default.post(name: .secureFolderDidOpen, object: nil)
        }
    }
    
    /// Locks the folder and stops auto-lock timer
    func lock() {
        isUnlocked = false
        stopAutoLockTimer()
        
        if folder.isSecure {
            NotificationCenter.default.post(name: .secureFolderDidClose, object: nil)
        }
    }
    
    // MARK: - Auto-Lock Timer
    
    /// Starts the auto-lock inactivity timer
    func startAutoLockTimer() {
        guard folder.isSecure else { return }
        stopAutoLockTimer()
        
        remainingSeconds = Int(autoLockTimeout)
        
        autoLockTimer = Timer.scheduledTimer(
            withTimeInterval: autoLockTimeout - TimeInterval(countdownWarningStart),
            repeats: false
        ) { [weak self] _ in
            self?.startCountdown()
        }
    }
    
    /// Resets the auto-lock timer (called on user interaction)
    func resetAutoLockTimer() {
        guard folder.isSecure, isUnlocked else { return }
        stopAutoLockTimer()
        startAutoLockTimer()
    }
    
    /// Stops all auto-lock timers
    func stopAutoLockTimer() {
        autoLockTimer?.invalidate()
        autoLockTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    /// Starts the countdown warning before auto-lock
    private func startCountdown() {
        remainingSeconds = countdownWarningStart
        delegate?.autoLockCountdown(remainingSeconds)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.remainingSeconds -= 1
            
            if self.remainingSeconds <= 0 {
                timer.invalidate()
                self.lock()
                self.delegate?.autoLockTriggered()
            } else {
                self.delegate?.autoLockCountdown(self.remainingSeconds)
            }
        }
    }
    
    // MARK: - File Operations
    
    /// Adds an image file to the folder
    /// - Parameters:
    ///   - image: The UIImage to save
    ///   - originalName: Original file name (optional)
    func addImage(_ image: UIImage, originalName: String? = nil) {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            delegate?.didEncounterError("Failed to process image.")
            return
        }
        
        // Check storage space
        guard storageManager.hasEnoughSpace(for: Int64(data.count)) else {
            delegate?.didEncounterError("Not enough storage space. Please free up some space and try again.")
            return
        }
        
        let name = originalName ?? "IMG_\(DateFormatter.fileNameFormatter.string(from: Date())).jpg"
        let fileItem = FileItem(fileName: name, fileExtension: "jpg", fileSize: Int64(data.count))
        
        guard storageManager.saveFile(data: data, fileName: fileItem.storageName, to: folder) != nil else {
            delegate?.didEncounterError("Failed to save image.")
            return
        }
        
        files.insert(fileItem, at: 0)
        saveFiles()
        
        delegate?.fileDidAdd(at: 0)
        resetAutoLockTimer()
    }
    
    /// Adds a file from a URL (documents, PDFs, etc.)
    /// - Parameter url: The source URL of the file
    func addFile(from url: URL) {
        // Start accessing the security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let data = try? Data(contentsOf: url) else {
            delegate?.didEncounterError("Failed to read the selected file.")
            return
        }
        
        // Check storage space
        guard storageManager.hasEnoughSpace(for: Int64(data.count)) else {
            delegate?.didEncounterError("Not enough storage space. Please free up some space and try again.")
            return
        }
        
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension
        
        let fileItem = FileItem(
            fileName: fileName,
            fileExtension: fileExtension,
            fileSize: Int64(data.count)
        )
        
        guard storageManager.saveFile(data: data, fileName: fileItem.storageName, to: folder) != nil else {
            delegate?.didEncounterError("Failed to save file.")
            return
        }
        
        files.insert(fileItem, at: 0)
        saveFiles()
        
        delegate?.fileDidAdd(at: 0)
        resetAutoLockTimer()
    }
    
    /// Adds a video from a URL
    /// - Parameter url: The source URL of the video
    func addVideo(from url: URL) {
        guard let data = try? Data(contentsOf: url) else {
            delegate?.didEncounterError("Failed to read the selected video.")
            return
        }
        
        // Check storage space
        guard storageManager.hasEnoughSpace(for: Int64(data.count)) else {
            delegate?.didEncounterError("Not enough storage space. Please free up some space and try again.")
            return
        }
        
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
        
        let fileItem = FileItem(
            fileName: fileName,
            fileExtension: fileExtension,
            fileSize: Int64(data.count)
        )
        
        guard storageManager.saveFile(data: data, fileName: fileItem.storageName, to: folder) != nil else {
            delegate?.didEncounterError("Failed to save video.")
            return
        }
        
        files.insert(fileItem, at: 0)
        saveFiles()
        
        delegate?.fileDidAdd(at: 0)
        resetAutoLockTimer()
    }
    
    /// Deletes a file at the given index
    func deleteFile(at index: Int) {
        guard index >= 0 && index < files.count else { return }
        
        let file = files[index]
        storageManager.deleteFile(fileName: file.storageName, from: folder)
        
        files.remove(at: index)
        saveFiles()
        
        delegate?.fileDidDelete(at: index)
        resetAutoLockTimer()
    }
    
    /// Returns the file URL for previewing
    func fileURL(at index: Int) -> URL? {
        guard let file = file(at: index) else { return nil }
        return storageManager.fileURL(fileName: file.storageName, in: folder)
    }
    
    /// Gets thumbnail image for a file
    func thumbnail(for file: FileItem) -> UIImage? {
        return storageManager.createThumbnail(for: file, in: folder)
    }
    
    // MARK: - Persistence
    
    /// Loads file metadata from UserDefaults
    private func loadFiles() {
        guard let data = UserDefaults.standard.data(forKey: filesKey) else {
            files = []
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode([FileItem].self, from: data)
            files = decoded.sorted { $0.addedAt > $1.addedAt }
        } catch {
            print("[FolderDetailViewModel] Failed to decode files: \(error)")
            files = []
        }
    }
    
    /// Saves file metadata to UserDefaults
    private func saveFiles() {
        do {
            let data = try JSONEncoder().encode(files)
            UserDefaults.standard.set(data, forKey: filesKey)
        } catch {
            print("[FolderDetailViewModel] Failed to encode files: \(error)")
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    /// Formatter for generating file names from dates
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}
