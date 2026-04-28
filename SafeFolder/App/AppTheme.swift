//
//  AppTheme.swift
//  SafeFolder
//
//  Centralized design system with colors, fonts, and styling constants.
//  Supports both Light and Dark mode automatically.
//

import UIKit

/// Centralized theme configuration for the entire app.
/// Uses a deep navy / dark palette with electric blue accent.
struct AppTheme {
    
    // MARK: - Colors
    
    /// Primary background — deep navy in both modes
    static var primaryBackground: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.06, green: 0.07, blue: 0.13, alpha: 1.0) // #0F1221
            default:
                return UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0) // #F3F5FA
            }
        }
    }
    
    /// Secondary background for cards and elevated surfaces
    static var cardBackground: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.10, green: 0.11, blue: 0.19, alpha: 1.0) // #1A1C30
            default:
                return UIColor.white
            }
        }
    }
    
    /// Tertiary background for nested elements
    static var tertiaryBackground: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.14, green: 0.15, blue: 0.24, alpha: 1.0) // #24263D
            default:
                return UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0) // #F0F2F8
            }
        }
    }
    
    /// Electric blue accent color
    static var accentColor: UIColor {
        UIColor(red: 0.25, green: 0.47, blue: 1.0, alpha: 1.0) // #4078FF
    }
    
    /// Purple gradient end color
    static var accentGradientEnd: UIColor {
        UIColor(red: 0.55, green: 0.30, blue: 1.0, alpha: 1.0) // #8C4DFF
    }
    
    /// Success green
    static var successColor: UIColor {
        UIColor(red: 0.20, green: 0.84, blue: 0.55, alpha: 1.0) // #34D68C
    }
    
    /// Warning/error red
    static var errorColor: UIColor {
        UIColor(red: 1.0, green: 0.30, blue: 0.37, alpha: 1.0) // #FF4D5E
    }
    
    /// Warning yellow
    static var warningColor: UIColor {
        UIColor(red: 1.0, green: 0.76, blue: 0.18, alpha: 1.0) // #FFC22E
    }
    
    /// Primary text color
    static var primaryText: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.white
            default:
                return UIColor(red: 0.10, green: 0.11, blue: 0.19, alpha: 1.0)
            }
        }
    }
    
    /// Secondary text color (subtitles, captions)
    static var secondaryText: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.60, green: 0.62, blue: 0.72, alpha: 1.0) // #999EB8
            default:
                return UIColor(red: 0.45, green: 0.47, blue: 0.55, alpha: 1.0)
            }
        }
    }
    
    /// Separator / border color
    static var separator: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.18, green: 0.19, blue: 0.28, alpha: 1.0)
            default:
                return UIColor(red: 0.88, green: 0.89, blue: 0.92, alpha: 1.0)
            }
        }
    }
    
    // MARK: - Gradients
    
    /// Creates the accent gradient layer (electric blue → purple)
    static func accentGradientLayer(frame: CGRect) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [accentColor.cgColor, accentGradientEnd.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = frame
        return gradient
    }
    
    /// Subtle card gradient for folder cards
    static func cardGradientLayer(frame: CGRect) -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.16, green: 0.17, blue: 0.28, alpha: 1.0).cgColor,
            UIColor(red: 0.12, green: 0.13, blue: 0.22, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = frame
        return gradient
    }
    
    // MARK: - Typography
    
    /// Large title font (34pt bold)
    static let largeTitleFont = UIFont.systemFont(ofSize: 34, weight: .bold)
    
    /// Title font (22pt bold)
    static let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
    
    /// Headline font (17pt semibold)
    static let headlineFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    
    /// Body font (16pt regular)
    static let bodyFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    
    /// Subhead font (14pt medium)
    static let subheadFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    
    /// Caption font (12pt regular)
    static let captionFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    
    /// Small caption font (10pt medium)
    static let smallCaptionFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    
    // MARK: - Layout Constants
    
    /// Standard corner radius for cards
    static let cardCornerRadius: CGFloat = 16
    
    /// Standard padding
    static let padding: CGFloat = 16
    
    /// Small padding
    static let smallPadding: CGFloat = 8
    
    /// Large padding
    static let largePadding: CGFloat = 24
    
    // MARK: - Shadow
    
    /// Apply standard card shadow to a view
    static func applyCardShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.15
        view.layer.masksToBounds = false
    }
    
    /// Apply subtle shadow
    static func applySubtleShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.08
        view.layer.masksToBounds = false
    }
}
