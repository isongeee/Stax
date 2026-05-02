import SwiftUI

/// Single-line text input with leading icon, error state, and focus tracking.
///
/// ```swift
/// StaxInput("Search decks…", text: $query, icon: "magnifyingglass")
/// StaxInput("Document title", text: $title, error: titleError)
/// ```
struct StaxInput: View {

    private let placeholder: String
    @Binding private var text: String
    private let icon: String?
    private let error: String?
    private let keyboard: UIKeyboardType
    private let submitLabel: SubmitLabel

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        error: String? = nil,
        keyboard: UIKeyboardType = .default,
        submitLabel: SubmitLabel = .return
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.error = error
        self.keyboard = keyboard
        self.submitLabel = submitLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(DesignTokens.Component.Input.placeholderFg)
                        .accessibilityHidden(true)
                }
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .keyboardType(keyboard)
                    .submitLabel(submitLabel)
                    .staxText(.body)
                    .foregroundStyle(DesignTokens.Component.Input.textFg)
                    .tint(DesignTokens.Color.Role.focusRing)
                    .accessibilityLabel(placeholder)
                    .accessibilityHint(error ?? "")
            }
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .background(DesignTokens.Component.Input.bg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .animation(.easeOut(duration: DesignTokens.Motion.fast), value: isFocused)
            .animation(.easeOut(duration: DesignTokens.Motion.fast), value: error)

            if let error {
                Text(error)
                    .staxText(.caption)
                    .foregroundStyle(DesignTokens.Color.Role.textDanger)
                    .accessibilityHidden(true) // already announced via hint above
            }
        }
    }

    private var borderColor: Color {
        if error != nil { return DesignTokens.Component.Input.borderError }
        return DesignTokens.Component.Input.border(isFocused ? .focused : .default)
    }

    private var borderWidth: CGFloat { isFocused || error != nil ? 1.5 : 1 }
}

// MARK: - Previews
//
// State matrix: empty / filled / error / disabled. Focused state is visible
// when the live preview is interacted with (taps the field).

#Preview("State matrix") {
    StaxInputPreviewHost()
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Color.Role.bgCanvas)
}

private struct StaxInputPreviewHost: View {
    @State private var empty = ""
    @State private var filled = "Biology Chapter 4"
    @State private var errored = "not-an-email"
    @State private var disabled = "Read-only value"

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("Default (empty)") {
                StaxInput("Search decks…", text: $empty, icon: "magnifyingglass")
            }
            StaxStateGrid("Filled") {
                StaxInput("Document title", text: $filled)
            }
            StaxStateGrid("Error") {
                StaxInput("Email", text: $errored,
                          error: "Doesn't look like a valid email.",
                          keyboard: .emailAddress, submitLabel: .done)
            }
            StaxStateGrid("Disabled") {
                StaxInput("Document title", text: $disabled).disabled(true)
            }
        }
    }
}
