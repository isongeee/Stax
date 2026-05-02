import SwiftUI

/// Compact stat tile from `06 — Components.png` (the "Cards 48 / Studied 12 /
/// Due Today 6 / Retention 84%" row). Pair these in a `LazyVGrid` for the
/// dashboard summary.
///
/// ```swift
/// StaxStatCard(value: "48",  label: "Cards",    accent: .brand)
/// StaxStatCard(value: "84%", label: "Retention", accent: .success, trend: .up("+5%"))
/// ```
struct StaxStatCard: View {

    enum Accent { case brand, success, warning, danger, info, neutral }

    enum Trend {
        case up(String), down(String), flat(String)
        var label: String {
            switch self { case .up(let s), .down(let s), .flat(let s): return s }
        }
        var icon: String {
            switch self { case .up: "arrow.up.right"; case .down: "arrow.down.right"; case .flat: "arrow.right" }
        }
        var color: Color {
            switch self {
            case .up:   return DesignTokens.Color.Role.textSuccess
            case .down: return DesignTokens.Color.Role.textDanger
            case .flat: return DesignTokens.Color.Role.textSecondary
            }
        }
        var spokenLabel: String {
            switch self {
            case .up(let s):   return "trending up by \(s)"
            case .down(let s): return "trending down by \(s)"
            case .flat(let s): return "flat at \(s)"
            }
        }
    }

    private let value: String
    private let label: String
    private let icon: String?
    private let accent: Accent
    private let trend: Trend?

    init(
        value: String,
        label: String,
        icon: String? = nil,
        accent: Accent = .brand,
        trend: Trend? = nil
    ) {
        self.value = value
        self.label = label
        self.icon = icon
        self.accent = accent
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .imageScale(.medium)
                        .foregroundStyle(accentColor)
                        .accessibilityHidden(true)
                }
                Spacer()
                if let trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .imageScale(.small)
                            .accessibilityHidden(true)
                        Text(trend.label).staxText(.caption).fontWeight(.medium)
                    }
                    .foregroundStyle(trend.color)
                }
            }

            Text(value)
                .staxText(.h1)
                .foregroundStyle(accentColor)

            Text(label)
                .staxText(.caption)
                .fontWeight(.medium)
                .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                .textCase(.uppercase)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Color.Role.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(DesignTokens.Color.Role.borderSubtle, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = ["\(label): \(value)"]
        if let trend { parts.append(trend.spokenLabel) }
        return parts.joined(separator: ", ")
    }

    private var accentColor: Color {
        switch accent {
        case .brand:   return DesignTokens.Color.Role.iconBrand
        case .success: return DesignTokens.Color.Role.textSuccess
        case .warning: return DesignTokens.Color.Role.textWarning
        case .danger:  return DesignTokens.Color.Role.textDanger
        case .info:    return DesignTokens.Color.Role.textInfo
        case .neutral: return DesignTokens.Color.Role.textPrimary
        }
    }
}

// MARK: - Previews

#Preview("State matrix") {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("Default dashboard row") {
                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                    StaxStatCard(value: "48",  label: "Cards",     icon: "rectangle.stack",  accent: .brand)
                    StaxStatCard(value: "12",  label: "Studied",   icon: "checkmark.circle", accent: .success, trend: .up("+3"))
                    StaxStatCard(value: "6",   label: "Due Today", icon: "clock",            accent: .warning)
                    StaxStatCard(value: "84%", label: "Retention", icon: "chart.line.uptrend.xyaxis", accent: .success, trend: .up("+5%"))
                }
            }
            StaxStateGrid("All accents") {
                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                    StaxStatCard(value: "1",  label: "Brand",   accent: .brand)
                    StaxStatCard(value: "2",  label: "Success", accent: .success)
                    StaxStatCard(value: "3",  label: "Warning", accent: .warning)
                    StaxStatCard(value: "4",  label: "Danger",  accent: .danger)
                    StaxStatCard(value: "5",  label: "Info",    accent: .info)
                    StaxStatCard(value: "6",  label: "Neutral", accent: .neutral)
                }
            }
            StaxStateGrid("Trend variants") {
                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                    StaxStatCard(value: "+3",  label: "Up",   accent: .brand,   trend: .up("+10%"))
                    StaxStatCard(value: "-2",  label: "Down", accent: .danger,  trend: .down("-4%"))
                    StaxStatCard(value: "0",   label: "Flat", accent: .neutral, trend: .flat("0%"))
                }
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}
