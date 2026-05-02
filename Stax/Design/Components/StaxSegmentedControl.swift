import SwiftUI

/// Custom segmented selector matching `05 — Controls.png`.
///
/// Generic over `Hashable` selection values so it works with enums or strings:
///
/// ```swift
/// enum Side: Hashable { case front, back, both }
/// @State var side: Side = .front
/// StaxSegmentedControl(selection: $side, options: [
///     .init(.front, "Front"), .init(.back, "Back"), .init(.both, "Both"),
/// ])
/// ```
struct StaxSegmentedControl<Value: Hashable>: View {

    struct Option: Identifiable {
        let value: Value
        let label: String
        var id: Value { value }
        init(_ value: Value, _ label: String) {
            self.value = value
            self.label = label
        }
    }

    @Binding private var selection: Value
    private let options: [Option]
    @Namespace private var namespace

    init(selection: Binding<Value>, options: [Option]) {
        self._selection = selection
        self.options = options
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                segment(for: option)
            }
        }
        .padding(DesignTokens.Spacing.xs)
        .background(DesignTokens.Color.Role.bgMuted)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .frame(minHeight: DesignTokens.A11y.minTouchTarget)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func segment(for option: Option) -> some View {
        let isSelected = option.value == selection
        Button {
            withAnimation(.spring(response: DesignTokens.Motion.base, dampingFraction: 0.8)) {
                selection = option.value
            }
        } label: {
            Text(option.label)
                .staxText(.bodySmall)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(
                    isSelected
                    ? DesignTokens.Color.Role.textPrimary
                    : DesignTokens.Color.Role.textSecondary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                            .fill(DesignTokens.Color.Role.bgSurface)
                            .matchedGeometryEffect(id: "stax.segmented.thumb", in: namespace)
                            .staxShadow(DesignTokens.Shadow.e1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Previews

#Preview("State matrix") {
    StaxSegmentedControlPreviewHost()
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Color.Role.bgCanvas)
}

private struct StaxSegmentedControlPreviewHost: View {
    enum Side: Hashable { case front, back, both }
    enum Density: Hashable { case compact, regular, comfortable }

    @State private var side: Side = .front
    @State private var density: Density = .regular
    @State private var disabledSide: Side = .back

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("Default (3 options)") {
                StaxSegmentedControl(selection: $side, options: [
                    .init(.front, "Front"),
                    .init(.back, "Back"),
                    .init(.both, "Both"),
                ])
            }
            StaxStateGrid("Default (3 options, longer labels)") {
                StaxSegmentedControl(selection: $density, options: [
                    .init(.compact, "Compact"),
                    .init(.regular, "Regular"),
                    .init(.comfortable, "Comfortable"),
                ])
            }
            StaxStateGrid("Disabled") {
                StaxSegmentedControl(selection: $disabledSide, options: [
                    .init(.front, "Front"),
                    .init(.back, "Back"),
                    .init(.both, "Both"),
                ])
                .disabled(true)
            }
        }
    }
}
