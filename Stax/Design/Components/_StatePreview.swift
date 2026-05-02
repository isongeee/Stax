import SwiftUI

/// Internal preview helpers — labelled state rows / sections used by the
/// `#Preview` blocks of every Stax component to render a default / selected /
/// disabled / destructive state matrix consistently.
///
/// Underscore-prefixed filename keeps it adjacent to components in the file
/// browser. The types are not `private` so component preview blocks can use
/// them, but they're only intended for previews.

struct StaxStateRow<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .staxText(.label)
                .fontWeight(.semibold)
                .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                .textCase(.uppercase)
            HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
                content
            }
        }
    }
}

struct StaxStateGrid<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .staxText(.label)
                .fontWeight(.semibold)
                .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                .textCase(.uppercase)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                content
            }
        }
    }
}
