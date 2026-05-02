import SwiftUI

/// Recent-deck row from `06 — Components.png`. Tappable; renders a leading
/// icon, title, subtitle, and a chevron accessory.
///
/// ```swift
/// StaxDeckListItem(
///     title: "Biology Chapter 4",
///     subtitle: "48 cards · 84% retention · Studied 2h ago",
///     icon: "leaf"
/// ) { /* navigate */ }
/// ```
struct StaxDeckListItem: View {

    private let title: String
    private let subtitle: String?
    private let icon: String
    private let badge: StaxBadge?
    private let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        icon: String = "rectangle.stack",
        badge: StaxBadge? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.action = action
    }

    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                        .fill(DesignTokens.Color.Role.bgBrandSubtle)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundStyle(DesignTokens.Color.Role.iconBrand)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(title)
                            .staxText(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                        badge
                    }
                    if let subtitle {
                        Text(subtitle)
                            .staxText(.bodySmall)
                            .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: DesignTokens.Spacing.sm)

                if action != nil {
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .background(DesignTokens.Color.Role.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .stroke(DesignTokens.Color.Role.borderSubtle, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityElement(children: .combine)
        .accessibilityLabel([title, subtitle].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(action != nil ? .isButton : [])
    }
}

// MARK: - Previews

#Preview("State matrix") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("Default (tappable)") {
                StaxDeckListItem(
                    title: "Biology Chapter 4",
                    subtitle: "48 cards · 84% retention · Studied 2h ago",
                    icon: "leaf"
                ) {}
            }
            StaxStateGrid("With badge") {
                StaxDeckListItem(
                    title: "Biology Chapter 4",
                    subtitle: "48 cards · Due now",
                    icon: "leaf",
                    badge: StaxBadge("Due", style: .warning)
                ) {}
            }
            StaxStateGrid("No subtitle") {
                StaxDeckListItem(title: "Quick deck", icon: "doc") {}
            }
            StaxStateGrid("Disabled (no action)") {
                StaxDeckListItem(title: "Empty deck", subtitle: "0 cards", icon: "doc")
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}
