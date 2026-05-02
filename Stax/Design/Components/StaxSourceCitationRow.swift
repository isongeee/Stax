import SwiftUI

/// Source citation row from `06 — Components.png`. Shows where a generated
/// flashcard came from — the source file, the document/source name, and an
/// optional subject tag — joined with em-dash separators.
///
/// ```swift
/// StaxSourceCitationRow(
///     fileName: "cellular_energy_production.pdf",
///     source:   "McGill Biology 101",
///     subject:  "biology",
///     pageNumber: 142
/// ) { /* open citation */ }
/// ```
struct StaxSourceCitationRow: View {

    private let fileName: String
    private let source: String?
    private let subject: String?
    private let pageNumber: Int?
    private let action: (() -> Void)?

    init(
        fileName: String,
        source: String? = nil,
        subject: String? = nil,
        pageNumber: Int? = nil,
        action: (() -> Void)? = nil
    ) {
        self.fileName = fileName
        self.source = source
        self.subject = subject
        self.pageNumber = pageNumber
        self.action = action
    }

    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "doc.text")
                    .imageScale(.small)
                    .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName)
                        .staxText(.bodySmall)
                        .fontWeight(.medium)
                        .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 4) {
                        ForEach(metaParts, id: \.self) { part in
                            if part != metaParts.first { dashSeparator }
                            Text(part).staxText(.caption)
                        }
                    }
                    .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                    .lineLimit(1)
                }

                Spacer(minLength: DesignTokens.Spacing.sm)

                if action != nil {
                    Image(systemName: "arrow.up.right.square")
                        .imageScale(.small)
                        .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(minHeight: DesignTokens.A11y.minTouchTarget)
            .background(DesignTokens.Color.Role.bgMuted)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .accessibilityHint(action != nil ? "Opens the source." : "")
        .accessibilityAddTraits(action != nil ? .isButton : [])
    }

    private var spokenLabel: String {
        var parts = ["Source: \(fileName)"]
        parts.append(contentsOf: metaParts)
        return parts.joined(separator: ", ")
    }

    private var metaParts: [String] {
        var parts: [String] = []
        if let source { parts.append(source) }
        if let subject { parts.append(subject) }
        if let pageNumber { parts.append("p. \(pageNumber)") }
        return parts
    }

    private var dashSeparator: some View {
        Text("—").staxText(.caption)
    }
}

// MARK: - Previews

#Preview("State matrix") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        StaxStateGrid("Full citation (tappable)") {
            StaxSourceCitationRow(
                fileName: "cellular_energy_production.pdf",
                source: "McGill Biology 101",
                subject: "biology",
                pageNumber: 142
            ) {}
        }
        StaxStateGrid("No page number") {
            StaxSourceCitationRow(
                fileName: "lecture_03_cells.pptx",
                source: "BIO 207",
                subject: "cellular biology"
            )
        }
        StaxStateGrid("Filename only") {
            StaxSourceCitationRow(fileName: "quick_notes.md")
        }
        StaxStateGrid("Long filename truncates") {
            StaxSourceCitationRow(
                fileName: "an_extremely_long_lecture_title_about_oxidative_phosphorylation_v3_final.pdf",
                source: "Biology",
                pageNumber: 42
            ) {}
        }
    }
    .padding(DesignTokens.Spacing.xl)
    .background(DesignTokens.Color.Role.bgCanvas)
}
