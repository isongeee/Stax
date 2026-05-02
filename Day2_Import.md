# Day 2: Document Import

Wire up `.fileImporter` so the user can pick a PDF or PPTX and end up with a real `Document` + `Deck` row in the library. No text extraction, no card generation yet — that's later. Goal: prove the file picker, format probing, security-scoped bookmark, SwiftData write, and persistence-across-launch all work end-to-end.

## Checklist

- [ ] Create `Stax/Import/` folder
- [ ] Create `Stax/Import/ImportError.swift`
- [ ] Create `Stax/Import/PDFImporter.swift`
- [ ] Create `Stax/Import/PPTXImporter.swift`
- [ ] Create `Stax/Import/ImportService.swift`
- [ ] Create `Stax/Library/` folder
- [ ] Create `Stax/Library/LibraryView.swift`
- [ ] Modify `Stax/ContentView.swift` — replace the placeholder with `LibraryView()`
- [ ] Build (⌘B) — must succeed
- [ ] Run on simulator — drag a sample PDF + a sample PPTX into Files, import each, confirm rows appear with correct page/slide counts
- [ ] Kill and relaunch app — rows persist
- [ ] Try a `.txt` or other unsupported file — friendly error alert, no crash

## Files

### `Stax/Import/ImportError.swift`

```swift
import Foundation

enum ImportError: LocalizedError {
    case unsupportedSourceKind(URL)
    case pdfReadFailed(URL)
    case pptxNotAZip(URL)
    case pptxNoSlides(URL)

    var errorDescription: String? {
        switch self {
        case .unsupportedSourceKind(let url):
            return "Unsupported file: \(url.lastPathComponent). Only PDF and PPTX are supported."
        case .pdfReadFailed(let url):
            return "Couldn't open PDF: \(url.lastPathComponent)."
        case .pptxNotAZip(let url):
            return "PPTX is corrupt or not a valid archive: \(url.lastPathComponent)."
        case .pptxNoSlides(let url):
            return "PPTX has no slides: \(url.lastPathComponent)."
        }
    }
}
```

### `Stax/Import/PDFImporter.swift`

```swift
import Foundation
import PDFKit

enum PDFImporter {
    struct Probe {
        let title: String
        let pageCount: Int
        let ocrUsed: Bool
    }

    static func probe(url: URL) throws -> Probe {
        guard let pdf = PDFDocument(url: url) else {
            throw ImportError.pdfReadFailed(url)
        }
        let metaTitle = pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        let title = (metaTitle?.isEmpty == false ? metaTitle : nil)
            ?? url.deletingPathExtension().lastPathComponent
        let firstPageText = pdf.page(at: 0)?.string ?? ""
        let ocrUsed = firstPageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Probe(title: title!, pageCount: pdf.pageCount, ocrUsed: ocrUsed)
    }
}
```

> `ocrUsed` is a heuristic flag for now — empty first-page text means the PDF is probably scanned. Actual OCR happens later (Gemma 4 vision per the build guide).

### `Stax/Import/PPTXImporter.swift`

```swift
import Foundation
import ZIPFoundation

enum PPTXImporter {
    struct Probe {
        let title: String
        let slideCount: Int
    }

    static func probe(url: URL) throws -> Probe {
        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ImportError.pptxNotAZip(url)
        }
        let slideCount = archive.reduce(into: 0) { count, entry in
            let path = entry.path
            guard path.hasPrefix("ppt/slides/slide"), path.hasSuffix(".xml") else { return }
            // Excludes ppt/slides/_rels/slideN.xml.rels because that path doesn't start with "ppt/slides/slide".
            count += 1
        }
        guard slideCount > 0 else { throw ImportError.pptxNoSlides(url) }
        return Probe(
            title: url.deletingPathExtension().lastPathComponent,
            slideCount: slideCount
        )
    }
}
```

### `Stax/Import/ImportService.swift`

```swift
import Foundation
import SwiftData

@MainActor
enum ImportService {
    @discardableResult
    static func importFile(at url: URL, into context: ModelContext) throws -> Document {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let document: Document

        switch url.pathExtension.lowercased() {
        case "pdf":
            let probe = try PDFImporter.probe(url: url)
            document = Document(
                title: probe.title,
                fileBookmark: try url.bookmarkData(),
                sourceKind: .pdf,
                pageOrSlideCount: probe.pageCount,
                ocrUsed: probe.ocrUsed
            )
        case "pptx":
            let probe = try PPTXImporter.probe(url: url)
            document = Document(
                title: probe.title,
                fileBookmark: try url.bookmarkData(),
                sourceKind: .pptx,
                pageOrSlideCount: probe.slideCount
            )
        default:
            throw ImportError.unsupportedSourceKind(url)
        }

        let deck = Deck(name: document.title, document: document)
        context.insert(document)
        context.insert(deck)
        try context.save()
        return document
    }
}
```

### `Stax/Library/LibraryView.swift`

```swift
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
```

### `Stax/ContentView.swift` — replace whole file

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SchemaV1.models, inMemory: true)
}
```

## Verification

1. `xcodebuild -project Stax.xcodeproj -scheme Stax -destination 'generic/platform=iOS Simulator' build` → `BUILD SUCCEEDED`.
2. Drag a sample PDF and a sample PPTX into the simulator's Files app (or use AirDrop / Finder share).
3. Launch Stax. Empty state shows "Tap + to import".
4. Tap + → pick the PDF → row appears: filename · `<n> pages · pending`.
5. Tap + → pick the PPTX → row appears: filename · `<n> slides · pending`.
6. Kill and relaunch the app. Both rows persist (proves SwiftData save committed).
7. Tap + → pick a `.txt` (or any non-PDF/PPTX) → alert "Unsupported file: …", no crash.

## Notes / gotchas

- **ZIPFoundation must already be linked** to the Stax target — the user added it in the uncommitted `project.pbxproj` edits. If `import ZIPFoundation` fails, fix the target package dependency first.
- **iOS file importer URLs are security-scoped.** Always wrap reads in `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`. Done in `ImportService.importFile`.
- **Bookmark data is just stored, not yet resolved.** Reading the file again on a later launch (for generation) is Day 4+ work; we'll need `URL(resolvingBookmarkData:bookmarkDataIsStale:)` then.
- **No background work in this slice.** PDFKit and ZIPFoundation parsing run on `MainActor`. For the page counts/title probe alone this is fine; once we extract full text in Day 3+, push to a background actor.
- **No deduplication.** Importing the same file twice creates two `Document`+`Deck` pairs. Acceptable for Day 2 — fix when there's a real reason (probably when generation costs money or time).
- **PPTX slide-path filter.** `path.hasPrefix("ppt/slides/slide")` excludes `ppt/slides/_rels/slideN.xml.rels` because the `_rels/` directory breaks the prefix match. Verified by inspection; add a unit test in Day 3+ if it ever matters.
- **`ocrUsed` is a flag, not a result.** First-page-text-empty is a cheap heuristic. Real OCR comes later.
- **`@Relationship` cascade still applies.** Deleting a `Document` deletes its `Deck` and (eventually) its `Card`s and `ReviewLog`s. Don't add a manual delete cascade — the schema does it.
- **Files-app permission.** The simulator's Files app may need iCloud Drive set up, or use "On My iPhone" to drop files in. If the picker comes up empty, that's why — not a bug.

## Out of scope (explicit)

- Text extraction beyond page/slide count
- Card generation (Pass 1 / Pass 2)
- Detail screen for a deck
- Delete / rename / reorder
- Background import progress UI
- File-size limits / paywall gating
- Image extraction from PDF/PPTX
