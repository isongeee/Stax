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
