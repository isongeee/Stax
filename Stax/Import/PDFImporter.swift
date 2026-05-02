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
        return Probe(title: title, pageCount: pdf.pageCount, ocrUsed: ocrUsed)
    }
}
