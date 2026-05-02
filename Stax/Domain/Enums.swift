import Foundation

enum CardKind: String, Codable, Sendable {
    case basic
    case cloze
}

enum ConceptType: String, Codable, Sendable {
    case definition
    case fact
    case relationship
    case process
    case comparison
    case rule
}

enum Difficulty: String, Codable, Sendable {
    case easy
    case medium
    case hard
}

enum Importance: String, Codable, Sendable {
    case critical
    case important
    case niceToKnow
}

enum SourceKind: String, Codable, Sendable {
    case pdf
    case pptx
}

enum GenerationStatus: String, Codable, Sendable {
    case pending
    case running
    case done
    case failed
}

enum RuntimeIdentifier: String, Codable, Sendable {
    case foundationModels
    case mlxGemma
}
