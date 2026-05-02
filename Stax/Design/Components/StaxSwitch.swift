import SwiftUI

/// Token-styled toggle switch.
///
/// ```swift
/// StaxSwitch(isOn: $offlineModeEnabled)
/// StaxSwitch("Offline mode", isOn: $offlineModeEnabled) // with leading label
/// ```
struct StaxSwitch: View {

    private let label: String?
    @Binding private var isOn: Bool

    init(_ label: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            if let label {
                Text(label)
                    .staxText(.body)
                    .foregroundStyle(DesignTokens.Color.Role.textPrimary)
            }
        }
        .toggleStyle(StaxSwitchStyle())
    }
}

/// `ToggleStyle` for using the Stax look with native `Toggle` directly.
struct StaxSwitchStyle: ToggleStyle {

    @Environment(\.isEnabled) private var isEnabled

    // Track / thumb dimensions — UNCERTAIN, derived from `05 — Controls.png`.
    private let trackWidth: CGFloat = 48
    private let trackHeight: CGFloat = 28
    private let thumbDiameter: CGFloat = 24
    private let thumbInset: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer(minLength: DesignTokens.Spacing.md)

            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(trackColor(isOn: configuration.isOn))
                    .frame(width: trackWidth, height: trackHeight)

                Circle()
                    .fill(DesignTokens.Color.Role.bgSurface)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .padding(thumbInset)
                    .staxShadow(DesignTokens.Shadow.e1)
            }
            .animation(.spring(response: DesignTokens.Motion.base, dampingFraction: 0.75), value: configuration.isOn)
            .contentShape(Capsule())
            .onTapGesture { configuration.isOn.toggle() }
            .opacity(isEnabled ? 1 : 0.5)
            .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
        }
    }

    private func trackColor(isOn: Bool) -> Color {
        // Track is a fill, not text — keep `neutralDisabled` here since
        // `Role.textDisabled` would mis-describe the role.
        if !isEnabled { return DesignTokens.Color.neutralDisabled }
        return isOn ? DesignTokens.Color.Role.focusRing : DesignTokens.Color.Role.borderSubtle
    }
}

// MARK: - Previews

#Preview("State matrix") {
    StaxSwitchPreviewHost()
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Color.Role.bgCanvas)
}

private struct StaxSwitchPreviewHost: View {
    @State private var on = true
    @State private var off = false
    @State private var disabledOn = true
    @State private var disabledOff = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("With label") {
                StaxSwitch("Default (off)", isOn: $off)
                StaxSwitch("Selected (on)", isOn: $on)
                StaxSwitch("Disabled, off",  isOn: $disabledOff).disabled(true)
                StaxSwitch("Disabled, on",   isOn: $disabledOn).disabled(true)
            }
            StaxStateRow("No label") {
                StaxSwitch(isOn: $off)
                StaxSwitch(isOn: $on)
                StaxSwitch(isOn: $disabledOff).disabled(true)
                StaxSwitch(isOn: $disabledOn).disabled(true)
            }
        }
    }
}
