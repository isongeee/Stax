import SwiftUI

/// Primary action button for the Stax design system.
///
/// Wraps a SwiftUI `Button` with `StaxButtonStyle`. Use the convenience
/// initializer for a labelled button with an optional leading SF Symbol,
/// or apply `StaxButtonStyle` directly to any `Button` for full control.
///
/// ```swift
/// StaxButton("Generate Flashcards", icon: "sparkles") { /* … */ }
///     .staxButtonVariant(.primary)
/// ```
struct StaxButton: View {

    enum Variant { case primary, secondary, tertiary, destructive }

    private let title: String
    private let icon: String?
    private let action: () -> Void
    private var variant: Variant = .primary
    private var fillsWidth: Bool = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .accessibilityHidden(true) // text label already announces the action
                }
                Text(title)
                if fillsWidth { Spacer(minLength: 0) }
            }
            .frame(maxWidth: fillsWidth ? .infinity : nil)
        }
        .buttonStyle(StaxButtonStyle(variant: variant))
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    func variant(_ variant: Variant) -> StaxButton {
        var copy = self; copy.variant = variant; return copy
    }

    func fillWidth(_ fill: Bool = true) -> StaxButton {
        var copy = self; copy.fillsWidth = fill; return copy
    }
}

// MARK: - ButtonStyle

/// Apply directly to any `Button` for the Stax look:
/// `Button("Tap") { }.buttonStyle(StaxButtonStyle(variant: .secondary))`
struct StaxButtonStyle: ButtonStyle {
    var variant: StaxButton.Variant = .primary

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let state: DesignTokens.InteractiveState = {
            if !isEnabled { return .disabled }
            if configuration.isPressed { return .pressed }
            return .default
        }()

        configuration.label
            .staxText(.body)
            .fontWeight(.semibold)
            .foregroundStyle(foreground(for: state))
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .background(background(for: state))
            .overlay(border(for: state))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .contentShape(Rectangle())
            .animation(.easeOut(duration: DesignTokens.Motion.fast), value: configuration.isPressed)
    }

    @ViewBuilder
    private func background(for state: DesignTokens.InteractiveState) -> some View {
        switch variant {
        case .primary:
            DesignTokens.Component.Button.Primary.bg(state)
        case .secondary:
            DesignTokens.Component.Button.Secondary.bg(state)
        case .tertiary:
            DesignTokens.Component.Button.Tertiary.bg(state)
        case .destructive:
            DesignTokens.Component.Button.Danger.bg(state)
        }
    }

    private func foreground(for state: DesignTokens.InteractiveState) -> Color {
        switch variant {
        case .primary:
            return state == .disabled
                ? DesignTokens.Component.Button.Primary.fgDisabled
                : DesignTokens.Component.Button.Primary.fg
        case .secondary:
            return state == .disabled
                ? DesignTokens.Component.Button.Secondary.fgDisabled
                : DesignTokens.Component.Button.Secondary.fg
        case .tertiary:
            return state == .disabled
                ? DesignTokens.Component.Button.Tertiary.fgDisabled
                : DesignTokens.Component.Button.Tertiary.fg
        case .destructive:
            return DesignTokens.Component.Button.Danger.fg
        }
    }

    @ViewBuilder
    private func border(for state: DesignTokens.InteractiveState) -> some View {
        if variant == .secondary {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .stroke(DesignTokens.Component.Button.Secondary.border(state), lineWidth: 1)
        }
    }
}

// MARK: - Previews
//
// State matrix: each variant in default and disabled states, plus a separate
// row demonstrating fill-width. Pressed state is interaction-only on iOS and
// is verified by tapping in the live preview.

#Preview("State matrix") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            StaxStateRow("Primary") {
                StaxButton("Default",  icon: "sparkles")     {}.variant(.primary)
                StaxButton("Disabled", icon: "sparkles")     {}.variant(.primary).disabled(true)
            }
            StaxStateRow("Secondary") {
                StaxButton("Default",  icon: "doc.badge.plus") {}.variant(.secondary)
                StaxButton("Disabled", icon: "doc.badge.plus") {}.variant(.secondary).disabled(true)
            }
            StaxStateRow("Tertiary") {
                StaxButton("Default",  action: {}).variant(.tertiary)
                StaxButton("Disabled", action: {}).variant(.tertiary).disabled(true)
            }
            StaxStateRow("Destructive") {
                StaxButton("Delete deck", icon: "trash") {}.variant(.destructive)
                StaxButton("Disabled",    icon: "trash") {}.variant(.destructive).disabled(true)
            }
            StaxStateRow("Fill width") {
                StaxButton("Generate Flashcards", icon: "sparkles") {}
                    .variant(.primary)
                    .fillWidth()
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}
