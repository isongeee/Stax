import SwiftUI

/// Compact pill for status, count, or category labels.
///
/// ```swift
/// StaxBadge("Online", style: .success)
/// StaxBadge("Offline AI", icon: "wifi.slash", style: .neutral)
/// ```
struct StaxBadge: View {

    enum Style { case brand, success, warning, danger, info, neutral }

    private let text: String
    private let icon: String?
    private let style: Style

    init(_ text: String, icon: String? = nil, style: Style = .neutral) {
        self.text = text
        self.icon = icon
        self.style = style
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .imageScale(.small)
                    .accessibilityHidden(true) // status conveyed by combined label below
            }
            Text(text)
        }
        .staxText(.caption)
        .fontWeight(.medium)
        .foregroundStyle(foreground)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .background(background)
        .clipShape(Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(border, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch style {
        case .brand:   return "\(text), badge"
        case .success: return "\(text), success"
        case .warning: return "\(text), warning"
        case .danger:  return "\(text), error"
        case .info:    return "\(text), info"
        case .neutral: return text
        }
    }

    private var foreground: Color {
        switch style {
        case .brand:   return DesignTokens.Color.Role.iconBrand
        case .success: return DesignTokens.Color.Role.textSuccess
        case .warning: return DesignTokens.Color.Role.textWarning
        case .danger:  return DesignTokens.Color.Role.textDanger
        case .info:    return DesignTokens.Color.Role.textInfo
        case .neutral: return DesignTokens.Color.Role.textSecondary
        }
    }

    private var background: Color {
        switch style {
        case .brand:   return DesignTokens.Color.Role.bgBrandSubtle
        case .success: return DesignTokens.Color.Role.bgSuccessSubtle
        case .warning: return DesignTokens.Color.Role.bgWarningSubtle
        case .danger:  return DesignTokens.Color.Role.bgDangerSubtle
        case .info:    return DesignTokens.Color.Role.bgInfoSubtle
        case .neutral: return DesignTokens.Color.Role.bgMuted
        }
    }

    private var border: Color {
        switch style {
        case .neutral: return DesignTokens.Color.Role.borderSubtle
        default:       return foreground.opacity(0.20) // UNCERTAIN — derived from foreground
        }
    }
}

// MARK: - Previews
//
// Badges are non-interactive — no pressed/disabled state. State matrix shows
// every style with and without an icon.

#Preview("State matrix") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        StaxStateRow("With icon") {
            StaxBadge("Online",     icon: "wifi",          style: .success)
            StaxBadge("Due today",  icon: "clock",         style: .warning)
            StaxBadge("Failed",     icon: "xmark.octagon", style: .danger)
        }
        StaxStateRow("With icon · cont’d") {
            StaxBadge("Imported",   icon: "checkmark",     style: .info)
            StaxBadge("Beta",       icon: "sparkles",      style: .brand)
            StaxBadge("Offline AI", icon: "wifi.slash",    style: .neutral)
        }
        StaxStateRow("Text only") {
            StaxBadge("Brand",   style: .brand)
            StaxBadge("Success", style: .success)
            StaxBadge("Warning", style: .warning)
        }
        StaxStateRow("Text only · cont’d") {
            StaxBadge("Danger",  style: .danger)
            StaxBadge("Info",    style: .info)
            StaxBadge("Neutral", style: .neutral)
        }
    }
    .padding(DesignTokens.Spacing.xl)
    .background(DesignTokens.Color.Role.bgCanvas)
}
