import SwiftUI

/// Surface container for grouped content. Defaults to the token-defined
/// padding, radius, border, and elevation from `Component.Card`.
///
/// ```swift
/// StaxCard {
///     Text("Biology Chapter 4").staxText(.h2)
///     Text("48 cards").staxText(.bodySmall)
/// }
/// ```
struct StaxCard<Content: View>: View {

    private let content: Content
    private var padding: CGFloat = DesignTokens.Component.Card.padding
    private var shadow: ShadowToken? = DesignTokens.Component.Card.shadow
    private var showsBorder: Bool = true

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Component.Card.bg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Component.Card.radius, style: .continuous))
            .overlay {
                if showsBorder {
                    RoundedRectangle(cornerRadius: DesignTokens.Component.Card.radius, style: .continuous)
                        .stroke(DesignTokens.Component.Card.border, lineWidth: 1)
                }
            }
            .modifier(OptionalShadow(shadow: shadow))
            .accessibilityElement(children: .contain) // group child semantics under the card
    }

    func padding(_ amount: CGFloat) -> StaxCard {
        var copy = self; copy.padding = amount; return copy
    }

    /// Pass `nil` to disable elevation, or a different `ShadowToken` to override.
    func shadow(_ token: ShadowToken?) -> StaxCard {
        var copy = self; copy.shadow = token; return copy
    }

    func border(_ shows: Bool) -> StaxCard {
        var copy = self; copy.showsBorder = shows; return copy
    }
}

private struct OptionalShadow: ViewModifier {
    let shadow: ShadowToken?
    func body(content: Content) -> some View {
        if let shadow {
            content.staxShadow(shadow)
        } else {
            content
        }
    }
}

// MARK: - Previews
//
// Card is a non-interactive surface — no pressed/disabled state. Matrix shows
// every supported configuration (border on/off × shadow on/off × custom padding).

#Preview("State matrix") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("Default (border + e1 shadow)") {
                StaxCard {
                    sampleContent
                }
            }
            StaxStateGrid("Borderless, no shadow") {
                StaxCard {
                    sampleContent
                }
                .border(false)
                .shadow(nil)
            }
            StaxStateGrid("Elevated (e2 shadow)") {
                StaxCard {
                    sampleContent
                }
                .shadow(DesignTokens.Shadow.e2)
            }
            StaxStateGrid("Custom padding (xs)") {
                StaxCard {
                    sampleContent
                }
                .padding(DesignTokens.Spacing.xs)
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}

private var sampleContent: some View {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
        Text("Biology Chapter 4")
            .staxText(.h3)
            .foregroundStyle(DesignTokens.Color.Role.textPrimary)
        Text("48 cards · 84% retention")
            .staxText(.bodySmall)
            .foregroundStyle(DesignTokens.Color.Role.textSecondary)
    }
}
