import SwiftUI

/// Pill-shaped binary toggle — flips between selected and unselected on tap.
/// For the iOS-style track/thumb switch, use `StaxSwitch` instead.
///
/// ```swift
/// StaxToggle("Mastered", icon: "checkmark.seal", isOn: $masteredOnly)
/// StaxToggle(icon: "bold", isOn: $isBold) // icon-only
/// ```
struct StaxToggle: View {

    private let label: String?
    private let icon: String?
    @Binding private var isOn: Bool

    init(_ label: String? = nil, icon: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.icon = icon
        self._isOn = isOn
    }

    var body: some View {
        Button {
            withAnimation(.easeOut(duration: DesignTokens.Motion.fast)) { isOn.toggle() }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .accessibilityHidden(true)
                }
                if let label { Text(label) }
            }
            .staxText(.bodySmall)
            .fontWeight(.semibold)
        }
        .buttonStyle(StaxToggleStyle(isOn: isOn))
        .accessibilityLabel(label ?? icon ?? "Toggle")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(isOn ? [.isSelected, .isButton] : .isButton)
    }
}

private struct StaxToggleStyle: ButtonStyle {
    let isOn: Bool

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .background(background(pressed: configuration.isPressed))
            .clipShape(Capsule(style: .continuous))
            .overlay(Capsule(style: .continuous).stroke(border, lineWidth: 1))
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: DesignTokens.Motion.fast), value: configuration.isPressed)
    }

    private var foreground: Color {
        isOn ? DesignTokens.Component.Button.Primary.fg : DesignTokens.Color.Role.textPrimary
    }

    private func background(pressed: Bool) -> Color {
        if isOn { return pressed ? DesignTokens.Component.Button.Primary.bg(.pressed)
                                 : DesignTokens.Component.Button.Primary.bg(.default) }
        return pressed ? DesignTokens.Color.Role.borderSubtle
                       : DesignTokens.Color.Role.bgSurface
    }

    private var border: Color {
        isOn ? .clear : DesignTokens.Color.Role.borderSubtle
    }
}

// MARK: - Previews

#Preview("State matrix") {
    StaxTogglePreviewHost()
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Color.Role.bgCanvas)
}

private struct StaxTogglePreviewHost: View {
    @State private var on = true
    @State private var off = false
    @State private var disabledOn = true
    @State private var disabledOff = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateRow("Label + icon") {
                StaxToggle("Default",  icon: "checkmark.seal", isOn: $off)
                StaxToggle("Selected", icon: "checkmark.seal", isOn: $on)
                StaxToggle("Disabled", icon: "checkmark.seal", isOn: $disabledOff).disabled(true)
                StaxToggle("Disabled", icon: "checkmark.seal", isOn: $disabledOn).disabled(true)
            }
            StaxStateRow("Icon only") {
                StaxToggle(icon: "bold",      isOn: $off)
                StaxToggle(icon: "italic",    isOn: $on)
                StaxToggle(icon: "underline", isOn: $off).disabled(true)
            }
            StaxStateRow("Label only") {
                StaxToggle("Default",  isOn: $off)
                StaxToggle("Selected", isOn: $on)
                StaxToggle("Disabled", isOn: $on).disabled(true)
            }
        }
    }
}
