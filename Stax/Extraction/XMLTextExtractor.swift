import Foundation

enum XMLTextExtractor {
    nonisolated static func textRuns(from data: Data) -> [String] {
        let delegate = TextRunParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.textRuns
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private final class TextRunParserDelegate: NSObject, XMLParserDelegate {
    private(set) var textRuns: [String] = []
    private var isReadingTextRun = false
    private var currentText = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName == "a:t" || elementName == "t" else { return }
        isReadingTextRun = true
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isReadingTextRun else { return }
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard isReadingTextRun, elementName == "a:t" || elementName == "t" else { return }
        textRuns.append(currentText)
        currentText = ""
        isReadingTextRun = false
    }
}
