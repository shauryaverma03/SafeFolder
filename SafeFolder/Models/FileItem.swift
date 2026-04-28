//
//  FileItem.swift
//  SafeFolder
//
//  Model representing a file stored within a folder.
//

import Foundation
import UIKit

/// Supported file type categories for display purposes
enum FileType: String, Codable {
    case image
    case video
    case pdf
    case document
    case other
    
    /// SF Symbol name for this file type
    var iconName: String {
        switch self {
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .pdf: return "doc.text.fill"
        case .document: return "doc.fill"
        case .other: return "doc.questionmark.fill"
        }
    }
    
    /// Tint color for the file type icon
    var iconColor: UIColor {
        switch self {
        case .image: return AppTheme.accentColor
        case .video: return AppTheme.errorColor
        case .pdf: return UIColor(red: 0.95, green: 0.30, blue: 0.20, alpha: 1.0)
        case .document: return AppTheme.accentGradientEnd
        case .other: return AppTheme.secondaryText
        }
    }
}

/// Represents a file stored within a folder
struct FileItem: Codable, Identifiable, Equatable {
    
    /// Unique identifier for the file
    let id: UUID
    
    /// Original file name with extension
    var fileName: String
    
    /// File extension (e.g., "jpg", "pdf")
    var fileExtension: String
    
    /// File type category
    var fileType: FileType
    
    /// File size in bytes
    var fileSize: Int64
    
    /// Date the file was added to the folder
    let addedAt: Date
    
    /// Name used for storage on disk (UUID-based to avoid conflicts)
    var storageName: String
    
    // MARK: - Initialization
    
    /// Creates a new FileItem
    /// - Parameters:
    ///   - fileName: Original name of the file
    ///   - fileExtension: File extension
    ///   - fileSize: Size in bytes
    init(fileName: String, fileExtension: String, fileSize: Int64) {
        self.id = UUID()
        self.fileName = fileName
        self.fileExtension = fileExtension.lowercased()
        self.fileType = FileItem.determineFileType(from: fileExtension)
        self.fileSize = fileSize
        self.addedAt = Date()
        self.storageName = "\(id.uuidString).\(fileExtension.lowercased())"
    }
    
    // MARK: - File Type Detection
    
    /// Determines the file type category from the extension
    static func determineFileType(from ext: String) -> FileType {
        let lowered = ext.lowercased()
        
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "heif", "bmp", "tiff", "webp"]
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv", "wmv"]
        let pdfExtensions = ["pdf"]
        let documentExtensions = ["doc", "docx", "txt", "rtf", "xls", "xlsx", "ppt", "pptx", "csv", "pages", "numbers", "keynote"]
        
        if imageExtensions.contains(lowered) { return .image }
        if videoExtensions.contains(lowered) { return .video }
        if pdfExtensions.contains(lowered) { return .pdf }
        if documentExtensions.contains(lowered) { return .document }
        return .other
    }
    
    // MARK: - Computed Properties
    
    /// Formatted file size string (e.g., "2.4 MB")
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// Display name (truncated if too long)
    var displayName: String {
        let maxLength = 20
        if fileName.count > maxLength {
            let index = fileName.index(fileName.startIndex, offsetBy: maxLength - 3)
            return String(fileName[..<index]) + "..."
        }
        return fileName
    }
    
    /// Whether this file type can show a thumbnail preview
    var canShowThumbnail: Bool {
        return fileType == .image
    }
    
    // MARK: - Equatable
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        return lhs.id == rhs.id
    }
}
