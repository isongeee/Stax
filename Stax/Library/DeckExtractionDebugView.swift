import SwiftData
import SwiftUI

struct DeckExtractionDebugView: View {
    @Environment(\.modelContext) private var context

    let deck: Deck

    @State private var isExtracting = false
    @State private var extractionErrorMessage: String?
    @State private var extractionTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            DesignTokens.Color.Role.bgCanvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    summaryCard
                    chunksSection
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            extractionTask?.cancel()
            extractionTask = nil
        }
        .alert(
            "Extraction failed",
            isPresented: Binding(
                get: { extractionErrorMessage != nil },
                set: { if !$0 { extractionErrorMessage = nil } }
            ),
            presenting: extractionErrorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var summaryCard: some View {
        StaxCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(DesignTokens.Color.Role.iconBrand)
                        .frame(width: 44, height: 44)
                        .background(DesignTokens.Color.Role.bgBrandSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(deck.name)
                            .staxText(.h3)
                            .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                            .accessibilityAddTraits(.isHeader)

                        Text(documentSubtitle)
                            .staxText(.bodySmall)
                            .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    metadataRow("Extraction", value: extractionStatus)
                    metadataRow("Chunks", value: "\(chunks.count)")
                    if let importedAt = deck.document?.importedAt.formatted(date: .abbreviated, time: .shortened) {
                        metadataRow("Imported", value: importedAt)
                    }
                    if deck.document?.ocrUsed == true {
                        metadataRow("Scan hint", value: "First page had no selectable text")
                    }
                    if let error = deck.document?.extractionError, !error.isEmpty {
                        Text(error)
                            .staxText(.bodySmall)
                            .foregroundStyle(DesignTokens.Color.Role.textDanger)
                    }
                }

                StaxButton(isExtracting ? "Extracting..." : buttonTitle, icon: "text.page") {
                    extractText()
                }
                .fillWidth()
                .disabled(isExtracting || deck.document == nil)
            }
        }
    }

    @ViewBuilder
    private var chunksSection: some View {
        if chunks.isEmpty {
            StaxCard {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("No extracted chunks yet")
                        .staxText(.h3)
                        .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                    Text("Tap Extract Text to read selectable text from this document.")
                        .staxText(.bodySmall)
                        .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                }
            }
            .shadow(nil)
        } else {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Extracted Chunks")
                    .staxText(.h3)
                    .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                ForEach(chunks) { chunk in
                    StaxCard {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            HStack {
                                Text(label(for: chunk))
                                    .staxText(.bodySmall)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(DesignTokens.Color.Role.textPrimary)

                                Spacer()

                                Text("\(chunk.text.count) chars")
                                    .staxText(.caption)
                                    .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                            }

                            if let sourceTitle = chunk.sourceTitle, !sourceTitle.isEmpty {
                                Text(sourceTitle)
                                    .staxText(.caption)
                                    .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                                    .lineLimit(1)
                            }

                            Text(chunk.text)
                                .staxText(.bodySmall)
                                .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                                .lineLimit(8)
                                .textSelection(.enabled)
                        }
                    }
                    .shadow(nil)
                }
            }
        }
    }

    private var chunks: [SourceChunk] {
        (deck.document?.chunks ?? []).sorted { lhs, rhs in
            if lhs.sourceIndex == rhs.sourceIndex {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.sourceIndex < rhs.sourceIndex
        }
    }

    private var iconName: String {
        switch deck.document?.sourceKind {
        case .pdf: "doc.text"
        case .pptx: "rectangle.stack"
        case .none: "questionmark.circle"
        }
    }

    private var buttonTitle: String {
        chunks.isEmpty ? "Extract Text" : "Re-extract Text"
    }

    private var documentSubtitle: String {
        guard let document = deck.document else { return "Missing source document" }
        let unit = document.sourceKind == .pdf ? "pages" : "slides"
        return "\(document.pageOrSlideCount) \(unit) · \(document.sourceKind.rawValue.uppercased())"
    }

    private var extractionStatus: String {
        guard let document = deck.document else { return "missing source" }
        if isExtracting { return "extracting" }
        if document.extractionError?.isEmpty == false { return "failed" }
        if let extractedAt = document.extractedAt {
            return "extracted \(extractedAt.formatted(date: .abbreviated, time: .shortened))"
        }
        return "not extracted"
    }

    private func metadataRow(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .staxText(.bodySmall)
                .foregroundStyle(DesignTokens.Color.Role.textSecondary)
            Spacer()
            Text(value)
                .staxText(.bodySmall)
                .fontWeight(.medium)
                .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func label(for chunk: SourceChunk) -> String {
        switch deck.document?.sourceKind {
        case .pdf:
            return "Page \(chunk.sourceIndex)"
        case .pptx:
            return "Slide \(chunk.sourceIndex)"
        case .none:
            return "Source \(chunk.sourceIndex)"
        }
    }

    private func extractText() {
        guard let document = deck.document else {
            extractionErrorMessage = ExtractionError.missingDocument.localizedDescription
            return
        }

        extractionTask?.cancel()
        isExtracting = true
        extractionTask = Task {
            defer {
                isExtracting = false
                extractionTask = nil
            }

            do {
                try await TextExtractionService.extract(document: document, into: context)
            } catch is CancellationError {
                document.extractionError = nil
            } catch {
                extractionErrorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    let document = Document(
        title: "Biology Chapter 4",
        fileBookmark: Data(),
        sourceKind: .pdf,
        pageOrSlideCount: 12
    )
    let deck = Deck(name: "Biology Chapter 4", document: document)
    document.chunks = [
        SourceChunk(
            sourceIndex: 1,
            sourceTitle: "Page 1",
            text: "Mitochondria produce ATP through cellular respiration.",
            document: document
        )
    ]

    return NavigationStack {
        DeckExtractionDebugView(deck: deck)
    }
    .modelContainer(for: SchemaV1.models, inMemory: true)
}
