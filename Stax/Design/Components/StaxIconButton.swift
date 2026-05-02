import SwiftUI

/// Icon-only circular button. Always meets the 44pt touch target via an
/// invisible padded hit area, even when the visual size is smaller.
///
/// ```swift
/// StaxIconButton(systemName: "trash", variant: .destructive) { /* … */ }
/// StaxIconButton(systemName: "plus", variant: .primary, size: .large) { /* … */ }
/// ```
struct StaxIconButton: View {

    enum Variant { case primary, secondary, tertiary, destructive }
    enum Size {
        case small, medium, large
        var diameter: CGFloat {
            switch self { case .small: 32; case .medium: 40; case .large: 48 }
        }
        var iconScale: Image.Scale {
            switch self { case .small: .small; case .medium: .medium; case .large: .large }
        }
    }

    private let systemName: String
    private let variant: Variant
    private let size: Size
    private let action: () -> Void
    private let accessibilityLabel: String

    init(
        systemName: String,
        variant: Variant = .secondary,
        size: Size = .medium,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.variant = variant
        self.size = size
        self.action = action
        self.accessibilityLabel = accessibilityLabel ?? systemName
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .imageScale(size.iconScale)
                .frame(width: size.diameter, height: size.diameter)
                .accessibilityHidden(true) // label set on the Button below
        }
        .buttonStyle(StaxIconButtonStyle(variant: variant, diameter: size.diameter))
        .frame(minWidth: DesignTokens.A11y.minTouchTarget, minHeight: DesignTokens.A11y.minTouchTarget)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}

private struct StaxIconButtonStyle: ButtonStyle {
    let variant: StaxIconButton.Variant
    let diameter: CGFloat

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let state: DesignTokens.InteractiveState = {
            if !isEnabled { return .disabled }
            if configuration.isPressed { return .pressed }
            return .default
        }()

        configuration.label
            .font(.system(size: diameter * 0.45, weight: .semibold))
            .foregroundStyle(foreground(for: state))
            .background(background(for: state))
            .clipShape(Circle())
            .overlay {
                if variant == .secondary {
                    Circle().stroke(DesignTokens.Component.Button.Secondary.border(state), lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: DesignTokens.Motion.fast), value: configuration.isPressed)
    }

    @ViewBuilder
    private func background(for state: DesignTokens.InteractiveState) -> some View {
        switch variant {
        case .primary:     DesignTokens.Component.Button.Primary.bg(state)
        case .secondary:   DesignTokens.Component.Button.Secondary.bg(state)
        case .tertiary:    DesignTokens.Component.Button.Tertiary.bg(state)
        case .destructive: DesignTokens.Component.Button.Danger.bg(state)
        }
    }

    private func foreground(for state: DesignTokens.InteractiveState) -> Color {
        switch variant {
        case .primary:     return DesignTokens.Component.Button.Primary.fg
        case .secondary:   return state == .disabled ? DesignTokens.Color.Role.textDisabled : DesignTokens.Component.Button.Secondary.fg
        case .tertiary:    return state == .disabled ? DesignTokens.Color.Role.textDisabled : DesignTokens.Component.Button.Tertiary.fg
        case .destructive: return DesignTokens.Component.Button.Danger.fg
        }
    }
}

// MARK: - Previews

#Preview("State matrix") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        StaxStateRow("Primary") {
            StaxIconButton(systemName: "plus",  variant: .primary, accessibilityLabel: "Add") {}
            StaxIconButton(systemName: "plus",  variant: .primary, accessibilityLabel: "Add") {}.disabled(true)
        }
        StaxStateRow("Secondary") {
            StaxIconButton(systemName: "magnifyingglass", variant: .secondary, accessibilityLabel: "Search") {}
            StaxIconButton(systemName: "magnifyingglass", variant: .secondary, accessibilityLabel: "Search") {}.disabled(true)
        }
        StaxStateRow("Tertiary") {
            StaxIconButton(systemName: "ellipsis", variant: .tertiary, accessibilityLabel: "More") {}
            StaxIconButton(systemName: "ellipsis", variant: .tertiary, accessibilityLabel: "More") {}.disabled(true)
        }
        StaxStateRow("Destructive") {
            StaxIconButton(systemName: "trash", variant: .destructive, accessibilityLabel: "Delete") {}
            StaxIconButton(systemName: "trash", variant: .destructive, accessibilityLabel: "Delete") {}.disabled(true)
        }
        StaxStateRow("Sizes") {
            StaxIconButton(systemName: "play.fill", variant: .primary, size: .small,  accessibilityLabel: "Play") {}
            StaxIconButton(systemName: "play.fill", variant: .primary, size: .medium, accessibilityLabel: "Play") {}
            StaxIconButton(systemName: "play.fill", variant: .primary, size: .large,  accessibilityLabel: "Play") {}
        }
    }
    .padding(DesignTokens.Spacing.xl)
    .background(DesignTokens.Color.Role.bgCanvas)
}
