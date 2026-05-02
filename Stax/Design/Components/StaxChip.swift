import SwiftUI

/// Interactive pill — selectable filter chip and/or removable tag.
/// Differs from `StaxBadge` (which is non-interactive) by responding to taps
/// and supporting selection / removal affordances.
///
/// ```swift
/// // Selectable filter chip
/// StaxChip("Biology", icon: "leaf", isSelected: $bioSelected)
/// // Removable tag
/// StaxChip("anatomy", onRemove: { tags.removeAll { $0 == "anatomy" } })
/// // Read-only chip
/// StaxChip("Imported")
/// ```
struct StaxChip: View {

    private let text: String
    private let icon: String?
    @Binding private var isSelected: Bool
    private let onRemove: (() -> Void)?
    private let isInteractive: Bool

    /// Read-only chip.
    init(_ text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
        self._isSelected = .constant(false)
        self.onRemove = nil
        self.isInteractive = false
    }

    /// Selectable filter chip.
    init(_ text: String, icon: String? = nil, isSelected: Binding<Bool>) {
        self.text = text
        self.icon = icon
        self._isSelected = isSelected
        self.onRemove = nil
        self.isInteractive = true
    }

    /// Removable tag chip.
    init(_ text: String, icon: String? = nil, onRemove: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self._isSelected = .constant(false)
        self.onRemove = onRemove
        self.isInteractive = false
    }

    var body: some View {
        let state: DesignTokens.InteractiveState = isSelected ? .selected : .default

        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            Text(text).staxText(.bodySmall).fontWeight(.medium)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .imageScale(.small)
                        .padding(2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(text)")
            }
        }
        .foregroundStyle(DesignTokens.Component.Chip.fg(state))
        .padding(.vertical, DesignTokens.Spacing.xs)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background(DesignTokens.Component.Chip.bg(state))
        .clipShape(Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(DesignTokens.Component.Chip.border(state), lineWidth: 1))
        .frame(minHeight: DesignTokens.A11y.minTouchTarget * 0.75) // chips run smaller than buttons; whole row should still be reachable
        .contentShape(Capsule())
        .onTapGesture {
            guard isInteractive else { return }
            withAnimation(.easeOut(duration: DesignTokens.Motion.fast)) { isSelected.toggle() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isInteractive ? (isSelected ? [.isSelected, .isButton] : .isButton) : [])
    }
}

// MARK: - Previews

#Preview("State matrix") {
    StaxChipPreviewHost()
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Color.Role.bgCanvas)
}

private struct StaxChipPreviewHost: View {
    @State private var selectedOn = true
    @State private var selectedOff = false
    @State private var disabledSelected = true
    @State private var tags = ["anatomy", "cells", "energy"]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateRow("Selectable") {
                StaxChip("Default",  icon: "leaf", isSelected: $selectedOff)
                StaxChip("Selected", icon: "leaf", isSelected: $selectedOn)
                StaxChip("Disabled", icon: "leaf", isSelected: $disabledSelected).disabled(true)
            }
            StaxStateRow("Read-only") {
                StaxChip("Imported")
                StaxChip("Beta", icon: "sparkles")
            }
            StaxStateRow("Removable") {
                ForEach(tags, id: \.self) { tag in
                    StaxChip(tag) { tags.removeAll { $0 == tag } }
                }
            }
        }
    }
}
