import SwiftUI

/// Pre-reveal study card from `06 — Components.png`. Shows a question with
/// a single "Show Answer" CTA. Pair with `StaxFlashcardReviewCard` for the
/// post-reveal grading step.
///
/// ```swift
/// StaxStudyCard(
///     question: "What is photosynthesis?",
///     position: (current: 4, total: 12)
/// ) { /* reveal */ }
/// ```
struct StaxStudyCard: View {

    private let question: String
    private let hint: String?
    private let position: (current: Int, total: Int)?
    private let onShowAnswer: () -> Void

    init(
        question: String,
        hint: String? = nil,
        position: (current: Int, total: Int)? = nil,
        onShowAnswer: @escaping () -> Void
    ) {
        self.question = question
        self.hint = hint
        self.position = position
        self.onShowAnswer = onShowAnswer
    }

    var body: some View {
        StaxCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                if let position {
                    HStack {
                        Text("Card \(position.current) of \(position.total)")
                            .staxText(.caption)
                            .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                        Spacer()
                        ProgressView(value: Double(position.current), total: Double(position.total))
                            .progressViewStyle(.linear)
                            .frame(width: 80)
                            .tint(DesignTokens.Color.Role.focusRing)
                            .accessibilityLabel("Study progress")
                            .accessibilityValue("Card \(position.current) of \(position.total)")
                    }
                    .accessibilityElement(children: .combine)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(question)
                        .staxText(.h2)
                        .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    if let hint {
                        Text(hint)
                            .staxText(.bodySmall)
                            .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                            .accessibilityLabel("Hint: \(hint)")
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)

                StaxButton("Show Answer", icon: "eye", action: onShowAnswer)
                    .variant(.primary)
                    .fillWidth()
            }
        }
        .shadow(DesignTokens.Shadow.e2)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("State matrix") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("With position + hint") {
                StaxStudyCard(
                    question: "What is photosynthesis?",
                    hint: "Think: light, water, CO₂",
                    position: (current: 4, total: 12)
                ) {}
            }
            StaxStateGrid("Question only") {
                StaxStudyCard(question: "Define mitochondrion.") {}
            }
            StaxStateGrid("Long question") {
                StaxStudyCard(
                    question: "Explain the role of the electron transport chain in oxidative phosphorylation and how the proton gradient drives ATP synthesis.",
                    position: (current: 1, total: 8)
                ) {}
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}
