import PDFKit
import SwiftData
import Testing
import UIKit
import ZIPFoundation
@testable import Stax

struct StaxTests {
    @Test @MainActor func sourceChunkPersistsInMemory() throws {
        let context = try makeContext()
        let document = Document(
            title: "Biology",
            fileBookmark: Data(),
            sourceKind: .pdf,
            pageOrSlideCount: 1
        )
        let chunk = SourceChunk(
            sourceIndex: 1,
            sourceTitle: "Page 1",
            text: "Cells contain mitochondria.",
            document: document
        )

        context.insert(document)
        context.insert(chunk)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SourceChunk>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.document?.id == document.id)
        #expect(fetched.first?.text == "Cells contain mitochondria.")
    }

    @Test @MainActor func extractsTextFromPDFPages() async throws {
        let fixture = try Fixture()
        let pdfURL = fixture.url("biology.pdf")
        try makePDF(at: pdfURL, pages: [
            "Mitochondria produce ATP.",
            "Ribosomes synthesize proteins."
        ])
        let context = try makeContext()
        let document = try makeDocument(url: pdfURL, sourceKind: .pdf, pageCount: 2, context: context)

        let chunks = try await TextExtractionService.extract(document: document, into: context)

        #expect(chunks.count == 2)
        #expect(chunks[0].sourceIndex == 1)
        #expect(chunks[0].text.contains("Mitochondria"))
        #expect(chunks[1].sourceIndex == 2)
        #expect(chunks[1].text.contains("Ribosomes"))
        #expect(document.extractedAt != nil)
        #expect(document.extractionError == nil)
    }

    @Test @MainActor func extractsSlideAndSpeakerNoteTextFromPPTX() async throws {
        let fixture = try Fixture()
        let pptxURL = fixture.url("lecture.pptx")
        try makePPTX(
            at: pptxURL,
            slides: [
                1: ["Cell Energy", "ATP stores usable energy."],
                2: ["Protein Synthesis", "Ribosomes translate mRNA."]
            ],
            notes: [
                1: ["Speaker note: mitochondria are the focus."],
                2: ["Speaker note: connect codons to amino acids."]
            ]
        )
        let context = try makeContext()
        let document = try makeDocument(url: pptxURL, sourceKind: .pptx, pageCount: 2, context: context)

        let chunks = try await TextExtractionService.extract(document: document, into: context)

        #expect(chunks.count == 2)
        #expect(chunks[0].sourceIndex == 1)
        #expect(chunks[0].sourceTitle == "Cell Energy")
        #expect(chunks[0].text.contains("ATP stores usable energy."))
        #expect(chunks[0].text.contains("mitochondria are the focus"))
        #expect(chunks[1].text.contains("Ribosomes translate mRNA."))
        #expect(chunks[1].text.contains("connect codons"))
    }

    @Test @MainActor func followsPPTXNotesSlideRelationships() async throws {
        let fixture = try Fixture()
        let pptxURL = fixture.url("mismatched-notes.pptx")
        try makePPTX(
            at: pptxURL,
            slides: [
                1: ["Slide One", "Slides and notes do not need matching file numbers."]
            ],
            notes: [
                7: ["Speaker note from notesSlide7."]
            ],
            noteRelationships: [
                1: 7
            ]
        )
        let context = try makeContext()
        let document = try makeDocument(url: pptxURL, sourceKind: .pptx, pageCount: 1, context: context)

        let chunks = try await TextExtractionService.extract(document: document, into: context)

        #expect(chunks.count == 1)
        #expect(chunks[0].text.contains("Speaker note from notesSlide7."))
    }

    @Test @MainActor func retryReplacesExistingChunks() async throws {
        let fixture = try Fixture()
        let firstURL = fixture.url("first.pdf")
        let secondURL = fixture.url("second.pdf")
        try makePDF(at: firstURL, pages: ["Old extraction text."])
        try makePDF(at: secondURL, pages: ["Fresh extraction text."])

        let context = try makeContext()
        let document = try makeDocument(url: firstURL, sourceKind: .pdf, pageCount: 1, context: context)
        _ = try await TextExtractionService.extract(document: document, into: context)

        document.fileBookmark = try secondURL.bookmarkData()
        let chunks = try await TextExtractionService.extract(document: document, into: context)

        #expect(chunks.count == 1)
        #expect(chunks[0].text.contains("Fresh extraction text."))
        #expect(!chunks[0].text.contains("Old extraction text."))

        let persisted = try TextExtractionService.fetchChunks(for: document, in: context)
        #expect(persisted.count == 1)
    }

    @Test @MainActor func emptyPDFReportsNoExtractableText() async throws {
        let fixture = try Fixture()
        let pdfURL = fixture.url("empty.pdf")
        try makePDF(at: pdfURL, pages: [""])
        let context = try makeContext()
        let document = try makeDocument(url: pdfURL, sourceKind: .pdf, pageCount: 1, context: context)

        do {
            _ = try await TextExtractionService.extract(document: document, into: context)
            Issue.record("Expected extraction to fail for an empty PDF.")
        } catch {
            #expect(error.localizedDescription.contains("No extractable text"))
        }

        let chunks = try TextExtractionService.fetchChunks(for: document, in: context)
        #expect(chunks.isEmpty)
        #expect(document.extractedAt == nil)
        #expect(document.extractionError?.contains("No extractable text") == true)
    }
}

private func makeContext() throws -> ModelContext {
    let container = try PersistenceController.makeContainer(inMemory: true)
    return ModelContext(container)
}

@MainActor
private func makeDocument(
    url: URL,
    sourceKind: SourceKind,
    pageCount: Int,
    context: ModelContext
) throws -> Document {
    let document = Document(
        title: url.deletingPathExtension().lastPathComponent,
        fileBookmark: try url.bookmarkData(),
        sourceKind: sourceKind,
        pageOrSlideCount: pageCount
    )
    context.insert(document)
    try context.save()
    return document
}

private struct Fixture {
    let directory: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    func url(_ fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }
}

private func makePDF(at url: URL, pages: [String]) throws {
    let renderer = UIGraphicsPDFRenderer(
        bounds: CGRect(x: 0, y: 0, width: 612, height: 792)
    )

    try renderer.writePDF(to: url) { context in
        for page in pages {
            context.beginPage()
            let text = page as NSString
            text.draw(
                at: CGPoint(x: 72, y: 72),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ]
            )
        }
    }
}

private func makePPTX(
    at url: URL,
    slides: [Int: [String]],
    notes: [Int: [String]],
    noteRelationships: [Int: Int]? = nil
) throws {
    let archive = try Archive(url: url, accessMode: .create)
    let relationships = noteRelationships
        ?? Dictionary(uniqueKeysWithValues: notes.keys.map { ($0, $0) })

    for (index, runs) in slides {
        try addXML(
            xmlTextRuns(runs),
            to: archive,
            path: "ppt/slides/slide\(index).xml"
        )

        if let noteIndex = relationships[index] {
            try addXML(
                slideRelationshipXML(noteIndex: noteIndex),
                to: archive,
                path: "ppt/slides/_rels/slide\(index).xml.rels"
            )
        }
    }

    for (index, runs) in notes {
        try addXML(
            xmlTextRuns(runs),
            to: archive,
            path: "ppt/notesSlides/notesSlide\(index).xml"
        )
    }
}

private func addXML(_ xml: String, to archive: Archive, path: String) throws {
    let data = Data(xml.utf8)
    try archive.addEntry(
        with: path,
        type: .file,
        uncompressedSize: Int64(data.count)
    ) { position, size in
        data.subdata(in: Int(position)..<Int(position) + size)
    }
}

private func xmlTextRuns(_ runs: [String]) -> String {
    let body = runs.map { run in
        "<a:r><a:t>\(escapedXML(run))</a:t></a:r>"
    }
    .joined()

    return """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
      <p:cSld><p:spTree><p:sp><p:txBody><a:p>\(body)</a:p></p:txBody></p:sp></p:spTree></p:cSld>
    </p:sld>
    """
}

private func slideRelationshipXML(noteIndex: Int) -> String {
    """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/notesSlide" Target="../notesSlides/notesSlide\(noteIndex).xml"/>
    </Relationships>
    """
}

private func escapedXML(_ text: String) -> String {
    text.replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&apos;")
}
