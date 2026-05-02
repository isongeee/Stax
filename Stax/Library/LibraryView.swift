import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    @State private var pickerPresented = false
    @State private var importErrorMessage: String?
    @State private var navigationPath: [UUID] = []

    private static let allowedTypes: [UTType] = {
        var types: [UTType] = [.pdf]
        if let pptx = UTType(filenameExtension: "pptx") { types.append(pptx) }
        return types
    }()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("Stax")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            pickerPresented = true
                        } label: {
                            Label("Import", systemImage: "plus")
                        }
                        .tint(DesignTokens.Color.Role.textLink)
                    }
                }
                .fileImporter(
                    isPresented: $pickerPresented,
                    allowedContentTypes: Self.allowedTypes,
                    allowsMultipleSelection: false,
                    onCompletion: handleImport
                )
                .alert(
                    "Import failed",
                    isPresented: Binding(
                        get: { importErrorMessage != nil },
                        set: { if !$0 { importErrorMessage = nil } }
                    ),
                    presenting: importErrorMessage
                ) { _ in
                    Button("OK", role: .cancel) {}
                } message: { message in
                    Text(message)
                }
                .navigationDestination(for: UUID.self) { deckID in
                    if let deck = decks.first(where: { $0.id == deckID }) {
                        DeckExtractionDebugView(deck: deck)
                    } else {
                        ContentUnavailableView(
                            "Deck not found",
                            systemImage: "questionmark.folder",
                            description: Text("This deck is no longer available.")
                        )
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            DesignTokens.Color.Role.bgCanvas
                .ignoresSafeArea()

            if decks.isEmpty {
                emptyState
            } else {
                deckList
            }
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                StaxCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                                .fill(DesignTokens.Color.Role.bgBrandSubtle)
                                .frame(width: 56, height: 56)

                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(DesignTokens.Color.Role.iconBrand)
                                .accessibilityHidden(true)
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("No decks yet")
                                .staxText(.h2)
                                .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                                .accessibilityAddTraits(.isHeader)

                            Text("Import a PDF or PowerPoint to create your first study deck.")
                                .staxText(.body)
                                .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                        }

                        StaxButton("Import PDF or PowerPoint", icon: "plus") {
                            pickerPresented = true
                        }
                        .fillWidth()
                    }
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var deckList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                ForEach(decks) { deck in
                    StaxDeckListItem(
                        title: deck.name,
                        subtitle: subtitle(for: deck),
                        icon: iconName(for: deck),
                        badge: statusBadge(for: deck)
                    ) {
                        navigationPath.append(deck.id)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.xl)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            try ImportService.importFile(at: url, into: context)
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }

    private func iconName(for deck: Deck) -> String {
        switch deck.document?.sourceKind {
        case .pdf: "doc.text"
        case .pptx: "rectangle.stack"
        case .none: "questionmark.circle"
        }
    }

    private func subtitle(for deck: Deck) -> String {
        guard let doc = deck.document else { return statusText(for: deck) }
        let unit = doc.sourceKind == .pdf ? "pages" : "slides"
        return "\(doc.pageOrSlideCount) \(unit) · \(statusText(for: deck))"
    }

    private func statusText(for deck: Deck) -> String {
        switch deck.generationStatus {
        case .pending:
            "ready to generate"
        case .running:
            "generating"
        case .done:
            "generated"
        case .failed:
            "generation failed"
        }
    }

    private func statusBadge(for deck: Deck) -> StaxBadge {
        switch deck.generationStatus {
        case .pending:
            StaxBadge("Ready", icon: "checkmark.circle", style: .info)
        case .running:
            StaxBadge("Running", icon: "sparkles", style: .brand)
        case .done:
            StaxBadge("Done", icon: "checkmark", style: .success)
        case .failed:
            StaxBadge("Failed", icon: "xmark.octagon", style: .danger)
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: SchemaV1.models, inMemory: true)
}
