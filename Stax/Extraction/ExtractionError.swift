import Foundation

enum ExtractionError: LocalizedError {
    case missingDocument
    case staleBookmark(String)
    case unreadableBookmark(String)
    case noExtractableText(String)
    case pdfReadFailed(String)
    case pptxReadFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingDocument:
            return "This deck is missing its source document."
        case .staleBookmark(let title):
            return "Stax needs the file again before it can extract text from \(title)."
        case .unreadableBookmark(let title):
            return "Couldn't reopen the original file for \(title). Try importing it again."
        case .noExtractableText(let title):
            return "No extractable text was found in \(title). Scanned files will need OCR in a later build."
        case .pdfReadFailed(let title):
            return "Couldn't read text from \(title)."
        case .pptxReadFailed(let title):
            return "Couldn't read slides from \(title)."
        }
    }
}
