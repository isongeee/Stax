import Foundation
import SwiftData

@MainActor
enum TextExtractionService {
    @discardableResult
    static func extract(document: Document, into context: ModelContext) async throws -> [SourceChunk] {
        let request = ExtractionRequest(
            title: document.title,
            sourceKind: document.sourceKind,
            fileBookmark: document.fileBookmark
        )

        do {
            let extracted = try await extractChunks(for: request)

            try replaceChunks(for: document, with: extracted, in: context)

            guard !extracted.isEmpty else {
                document.extractedAt = nil
                document.extractionError = ExtractionError.noExtractableText(document.title).localizedDescription
                try context.save()
                throw ExtractionError.noExtractableText(document.title)
            }

            document.extractedAt = .now
            document.extractionError = nil
            try context.save()
            return try fetchChunks(for: document, in: context)
        } catch {
            document.extractionError = error.localizedDescription
            try? context.save()
            throw error
        }
    }

    private static func extractChunks(for request: ExtractionRequest) async throws -> [ExtractedSourceChunk] {
        try await Task.detached(priority: .userInitiated) {
            try BookmarkResolver.withResolvedURL(
                title: request.title,
                fileBookmark: request.fileBookmark
            ) { url in
                switch request.sourceKind {
                case .pdf:
                    try PDFTextExtractor.extract(url: url, title: request.title)
                case .pptx:
                    try PPTXTextExtractor.extract(url: url, title: request.title)
                }
            }
        }.value
    }

    private static func replaceChunks(
        for document: Document,
        with extracted: [ExtractedSourceChunk],
        in context: ModelContext
    ) throws {
        for chunk in try fetchChunks(for: document, in: context) {
            context.delete(chunk)
        }

        for source in extracted {
            let chunk = SourceChunk(
                sourceIndex: source.sourceIndex,
                sourceTitle: source.sourceTitle,
                text: source.text,
                document: document
            )
            context.insert(chunk)
        }
    }

    static func fetchChunks(for document: Document, in context: ModelContext) throws -> [SourceChunk] {
        let documentID = document.id
        var descriptor = FetchDescriptor<SourceChunk>(
            predicate: #Predicate { chunk in
                chunk.document?.id == documentID
            },
            sortBy: [SortDescriptor(\.sourceIndex)]
        )
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }
}

private struct ExtractionRequest: Sendable {
    let title: String
    let sourceKind: SourceKind
    let fileBookmark: Data
}
