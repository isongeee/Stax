import SwiftUI

/// Tappable export-format chip from `06 — Components.png` ("Anki / CSV / PDF").
/// More opinionated than `StaxChip`: always shows a format icon and an
/// arrow-down accessory to communicate "tap to export."
///
/// ```swift
/// StaxExportChip(format: .anki) { exporter.export(.anki) }
/// StaxExportChip(format: .custom(label: "Markdown", icon: "doc.text")) { … }
/// ```
struct StaxExportChip: View {

    enum Format {
        case anki, csv, pdf, json
        case custom(label: String, icon: String)

        var label: String {
            switch self {
            case .anki: "Anki"; case .csv: "CSV"; case .pdf: "PDF"; case .json: "JSON"
            case .custom(let label, _): label
            }
        }
        var icon: String {
            switch self {
            case .anki: "rectangle.stack.badge.play"
            case .csv:  "tablecells"
            case .pdf:  "doc.richtext"
            case .json: "curlybraces"
            case .custom(_, let icon): icon
            }
        }
    }

    private let format: Format
    private let action: () -> Void

    init(format: Format, action: @escaping () -> Void) {
        self.format = format
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: format.icon)
                    .imageScale(.medium)
                    .foregroundStyle(DesignTokens.Color.Role.iconBrand)
                    .accessibilityHidden(true)
                Text(format.label)
                    .staxText(.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                Image(systemName: "arrow.down.circle")
                    .imageScale(.small)
                    .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .background(DesignTokens.Color.Role.bgSurface)
            .clipShape(Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).stroke(DesignTokens.Color.Role.borderSubtle, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Export as \(format.label)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("State matrix") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        StaxStateRow("Built-in formats") {
            StaxExportChip(format: .anki) {}
            StaxExportChip(format: .csv)  {}
            StaxExportChip(format: .pdf)  {}
            StaxExportChip(format: .json) {}
        }
        StaxStateRow("Custom") {
            StaxExportChip(format: .custom(label: "Markdown", icon: "doc.text")) {}
            StaxExportChip(format: .custom(label: "Notion",   icon: "n.square")) {}
        }
        StaxStateRow("Disabled") {
            StaxExportChip(format: .anki) {}.disabled(true)
            StaxExportChip(format: .csv)  {}.disabled(true)
        }
    }
    .padding(DesignTokens.Spacing.xl)
    .background(DesignTokens.Color.Role.bgCanvas)
}
