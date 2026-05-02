import Foundation

enum XMLRelationshipExtractor {
    struct Relationship: Sendable {
        let type: String
        let target: String
    }

    nonisolated static func relationships(from data: Data) -> [Relationship] {
        let delegate = RelationshipParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.relationships
    }
}

private final class RelationshipParserDelegate: NSObject, XMLParserDelegate {
    private(set) var relationships: [XMLRelationshipExtractor.Relationship] = []

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        guard elementName == "Relationship",
              let type = attributeDict["Type"],
              let target = attributeDict["Target"] else {
            return
        }

        relationships.append(
            XMLRelationshipExtractor.Relationship(type: type, target: target)
        )
    }
}
