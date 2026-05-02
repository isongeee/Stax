import SwiftUI

/// File import status card from `06 — Components.png`. Shows the file name
/// plus the current import state (pending → importing → success / failed).
///
/// ```swift
/// StaxFileImportCard(fileName: "biology.pdf", state: .importing(progress: 0.65))
/// StaxFileImportCard(fileName: "chem.pptx",  state: .success)
/// ```
struct StaxFileImportCard: View {

    enum State: Equatable {
        case pending
        case importing(progress: Double)
        case success
        case failed(message: String)
    }

    private let fileName: String
    private let state: State
    private let onCancel: (() -> Void)?
    private let onRetry: (() -> Void)?

    init(
        fileName: String,
        state: State,
        onCancel: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) {
        self.fileName = fileName
        self.state = state
        self.onCancel = onCancel
        self.onRetry = onRetry
    }

    var body: some View {
        StaxCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: iconName)
                        .imageScale(.large)
                        .foregroundStyle(iconColor)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fileName)
                            .staxText(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                            .lineLimit(1)
                        Text(statusText)
                            .staxText(.caption)
                            .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                    }
                    Spacer(minLength: DesignTokens.Spacing.sm)
                    trailingControl
                }

                if case .importing(let progress) = state {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(DesignTokens.Color.Role.focusRing)
                        .accessibilityLabel("Import progress")
                        .accessibilityValue("\(Int(progress * 100)) percent")
                }

                if case .failed(let message) = state {
                    Text(message)
                        .staxText(.caption)
                        .foregroundStyle(DesignTokens.Color.Role.textDanger)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fileName), \(statusText)")
    }

    private var iconName: String {
        switch state {
        case .pending:    return "doc"
        case .importing:  return "arrow.up.doc"
        case .success:    return "checkmark.circle.fill"
        case .failed:     return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .pending:    return DesignTokens.Color.Role.textSecondary
        case .importing:  return DesignTokens.Color.Role.iconBrand
        case .success:    return DesignTokens.Color.Role.iconSuccess
        case .failed:     return DesignTokens.Color.Role.iconDanger
        }
    }

    private var statusText: String {
        switch state {
        case .pending:                          return "Waiting…"
        case .importing(let progress):          return "Importing… \(Int(progress * 100))%"
        case .success:                          return "Imported"
        case .failed:                           return "Import failed"
        }
    }

    @ViewBuilder
    private var trailingControl: some View {
        switch state {
        case .pending, .importing:
            if let onCancel {
                StaxIconButton(systemName: "xmark", variant: .tertiary, size: .small, accessibilityLabel: "Cancel", action: onCancel)
            }
        case .failed:
            if let onRetry {
                StaxIconButton(systemName: "arrow.clockwise", variant: .tertiary, size: .small, accessibilityLabel: "Retry", action: onRetry)
            }
        case .success:
            EmptyView()
        }
    }
}

// MARK: - Previews
//
// State matrix follows the `State` enum exactly: pending / importing / success / failed.

#Preview("State matrix") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("Pending") {
                StaxFileImportCard(fileName: "biology_chapter_4.pdf", state: .pending, onCancel: {})
            }
            StaxStateGrid("Importing") {
                StaxFileImportCard(fileName: "biology_chapter_4.pdf",
                                   state: .importing(progress: 0.65), onCancel: {})
            }
            StaxStateGrid("Success") {
                StaxFileImportCard(fileName: "biology_chapter_4.pdf", state: .success)
            }
            StaxStateGrid("Failed") {
                StaxFileImportCard(fileName: "scan.pdf",
                                   state: .failed(message: "OCR couldn't read this file."),
                                   onRetry: {})
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}
