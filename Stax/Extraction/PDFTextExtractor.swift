import Foundation
import PDFKit

enum PDFTextExtractor {
    nonisolated static func extract(url: URL, title: String) throws -> [ExtractedSourceChunk] {
        guard let pdf = PDFDocument(url: url) else {
            throw ExtractionError.pdfReadFailed(title)
        }

        var chunks: [ExtractedSourceChunk] = []
        for pageIndex in 0..<pdf.pageCount {
            let text = normalized(pdf.page(at: pageIndex)?.string ?? "")
            guard !text.isEmpty else { continue }
            chunks.append(
                ExtractedSourceChunk(
                    sourceIndex: pageIndex + 1,
                    sourceTitle: "Page \(pageIndex + 1)",
                    text: text
                )
            )
        }
        return chunks
    }

    private nonisolated static func normalized(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
