import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    @State private var pickerPresented = false
    @State private var importErrorMessage: String?

    private static let allowedTypes: [UTType] = {
        var types: [UTType] = [.pdf]
        if let pptx = UTType(filenameExtension: "pptx") { types.append(pptx) }
        return types
    }()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Stax")
                .toolbar {
                    Button {
                        pickerPresented = true
                    } label: {
                        Label("Import", systemImage: "plus")
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
        }
    }

    @ViewBuilder
    private var content: some View {
        if decks.isEmpty {
            ContentUnavailableView(
                "No decks yet",
                systemImage: "rectangle.stack",
                description: Text("Tap + to import a PDF or PowerPoint.")
            )
        } else {
            List(decks) { deck in
                DeckRow(deck: deck)
            }
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
}

private struct DeckRow: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch deck.document?.sourceKind {
        case .pdf: "doc.text"
        case .pptx: "rectangle.stack"
        case .none: "questionmark.circle"
        }
    }

    private var subtitle: String {
        guard let doc = deck.document else { return deck.generationStatus.rawValue }
        let unit = doc.sourceKind == .pdf ? "pages" : "slides"
        return "\(doc.pageOrSlideCount) \(unit) · \(deck.generationStatus.rawValue)"
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: SchemaV1.models, inMemory: true)
}
