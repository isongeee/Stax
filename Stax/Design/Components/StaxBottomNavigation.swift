import SwiftUI

/// Bottom tab bar matching `06 — Components.png` "Bottom Navigation".
/// Generic over the selection value so it composes with custom tab enums.
///
/// ```swift
/// enum Tab: Hashable { case home, decks, study, insights, settings }
/// @State var tab: Tab = .home
/// StaxBottomNavigation(selection: $tab, items: [
///     .init(.home,     "Home",     icon: "house"),
///     .init(.decks,    "Decks",    icon: "rectangle.stack"),
///     .init(.study,    "Study",    icon: "play.rectangle"),
///     .init(.insights, "Insights", icon: "chart.bar"),
///     .init(.settings, "Settings", icon: "gearshape"),
/// ])
/// ```
struct StaxBottomNavigation<Value: Hashable>: View {

    struct Item: Identifiable {
        let value: Value
        let label: String
        let icon: String
        var id: Value { value }
        init(_ value: Value, _ label: String, icon: String) {
            self.value = value
            self.label = label
            self.icon = icon
        }
    }

    @Binding private var selection: Value
    private let items: [Item]

    init(selection: Binding<Value>, items: [Item]) {
        self._selection = selection
        self.items = items
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tab(for: item)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .background(DesignTokens.Color.Role.bgSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(DesignTokens.Color.Role.borderSubtle)
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func tab(for item: Item) -> some View {
        let isSelected = item.value == selection
        Button {
            withAnimation(.easeOut(duration: DesignTokens.Motion.fast)) { selection = item.value }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: item.icon)
                    .imageScale(.large)
                    .symbolVariant(isSelected ? .fill : .none)
                    .accessibilityHidden(true)
                Text(item.label).staxText(.caption).fontWeight(.medium)
            }
            .foregroundStyle(
                isSelected ? DesignTokens.Color.Role.textLink : DesignTokens.Color.Role.textSecondary
            )
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Previews
//
// State matrix: shows the bar with each tab selected, plus an interactive
// instance at the bottom. Disabled-bar state isn't typical for bottom nav and
// is omitted; individual tabs follow the parent's `.disabled` state.

#Preview("State matrix") {
    StaxBottomNavigationPreviewHost()
        .background(DesignTokens.Color.Role.bgCanvas)
}

private enum _BNTab: Hashable { case home, decks, study, insights, settings }

private let _bnItems: [StaxBottomNavigation<_BNTab>.Item] = [
    .init(.home,     "Home",     icon: "house"),
    .init(.decks,    "Decks",    icon: "rectangle.stack"),
    .init(.study,    "Study",    icon: "play.rectangle"),
    .init(.insights, "Insights", icon: "chart.bar"),
    .init(.settings, "Settings", icon: "gearshape"),
]

private struct StaxBottomNavigationPreviewHost: View {
    @State private var live: _BNTab = .study
    @State private var home: _BNTab = .home
    @State private var decks: _BNTab = .decks
    @State private var insights: _BNTab = .insights

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                StaxStateGrid("Home selected") {
                    StaxBottomNavigation(selection: $home, items: _bnItems)
                }
                StaxStateGrid("Decks selected") {
                    StaxBottomNavigation(selection: $decks, items: _bnItems)
                }
                StaxStateGrid("Insights selected") {
                    StaxBottomNavigation(selection: $insights, items: _bnItems)
                }
                StaxStateGrid("Interactive (tap a tab)") {
                    StaxBottomNavigation(selection: $live, items: _bnItems)
                }
            }
            .padding(DesignTokens.Spacing.xl)
        }
    }
}
