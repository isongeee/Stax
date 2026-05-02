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
