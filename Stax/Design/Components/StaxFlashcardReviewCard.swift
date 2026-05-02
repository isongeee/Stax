import SwiftUI

/// Spaced-repetition review card from `06 — Components.png`. Shows the
/// question, the revealed answer, and four difficulty-rating buttons that
/// drive the FSRS scheduler.
///
/// ```swift
/// StaxFlashcardReviewCard(
///     question: "What process produces ATP in cells?",
///     answer:   "Cellular respiration in mitochondria",
///     source:   "Cellular Energy Production"
/// ) { rating in scheduler.record(rating) }
/// ```
struct StaxFlashcardReviewCard: View {

    /// Standard FSRS-compatible response grades.
    enum Rating: String, CaseIterable, Identifiable {
        case again, hard, good, easy
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var color: Color {
            switch self {
            case .again: return DesignTokens.Color.Role.textDanger
            case .hard:  return DesignTokens.Color.Role.textWarning
            case .good:  return DesignTokens.Color.Role.textSuccess
            case .easy:  return DesignTokens.Color.Role.textLink
            }
        }
        var accessibilityHint: String {
            switch self {
            case .again: return "I didn't remember this — show again soon"
            case .hard:  return "Difficult, but I got it"
            case .good:  return "I remembered this without effort"
            case .easy:  return "Trivially easy — show much later"
            }
        }
    }

    private let question: String
    private let answer: String
    private let source: String?
    private let onRespond: (Rating) -> Void

    init(
        question: String,
        answer: String,
        source: String? = nil,
        onRespond: @escaping (Rating) -> Void
    ) {
        self.question = question
        self.answer = answer
        self.source = source
        self.onRespond = onRespond
    }

    var body: some View {
        StaxCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text(question)
                    .staxText(.h3)
                    .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Divider().background(DesignTokens.Color.Role.borderSubtle)

                Text(answer)
                    .staxText(.body)
                    .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let source {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "book.closed")
                            .imageScale(.small)
                            .accessibilityHidden(true)
                        Text(source).staxText(.caption)
                    }
                    .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Source: \(source)")
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(Rating.allCases) { rating in
                        Button(rating.label) { onRespond(rating) }
                            .buttonStyle(RatingButtonStyle(tint: rating.color))
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Rate \(rating.label)")
                            .accessibilityHint(rating.accessibilityHint)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct RatingButtonStyle: ButtonStyle {
    let tint: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .staxText(.bodySmall)
            .fontWeight(.semibold)
            .foregroundStyle(tint)
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .background(tint.opacity(configuration.isPressed ? 0.18 : 0.10)) // UNCERTAIN — derived
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1))
            .animation(.easeOut(duration: DesignTokens.Motion.fast), value: configuration.isPressed)
    }
}

// MARK: - Previews
//
// State matrix: with source, without source, and a long-answer wrap test.
// Rating-button pressed state is interaction-only.

#Preview("State matrix") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("With source") {
                StaxFlashcardReviewCard(
                    question: "What process produces ATP in cells?",
                    answer:   "Cellular respiration in the mitochondria — the citric acid cycle and oxidative phosphorylation.",
                    source:   "Cellular Energy Production · p. 142"
                ) { _ in }
            }
            StaxStateGrid("Without source") {
                StaxFlashcardReviewCard(
                    question: "Define mitochondrion.",
                    answer:   "A double-membrane organelle that produces ATP via oxidative phosphorylation."
                ) { _ in }
            }
            StaxStateGrid("Long content") {
                StaxFlashcardReviewCard(
                    question: "What is the citric acid cycle and how does it relate to oxidative phosphorylation?",
                    answer:   "The citric acid cycle (Krebs cycle) is a series of chemical reactions that generate energy through the oxidation of acetyl-CoA into CO₂ and NADH/FADH₂. The reduced electron carriers then feed the electron transport chain, driving oxidative phosphorylation to produce ATP.",
                    source:   "Cellular Energy Production · p. 142"
                ) { _ in }
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}
