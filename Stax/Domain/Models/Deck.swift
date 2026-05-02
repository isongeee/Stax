import Foundation
import SwiftData

@Model
final class Deck {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var generationStatusRaw: String
    var generationProgress: Double
    var generationError: String?
    var runtimeUsedRaw: String?

    var document: Document?

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    init(
        id: UUID = UUID(),
        name: String,
        document: Document? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = .now
        self.generationStatusRaw = GenerationStatus.pending.rawValue
        self.generationProgress = 0
        self.document = document
    }

    var generationStatus: GenerationStatus {
        get { GenerationStatus(rawValue: generationStatusRaw) ?? .pending }
        set { generationStatusRaw = newValue.rawValue }
    }

    var runtimeUsed: RuntimeIdentifier? {
        get { runtimeUsedRaw.flatMap(RuntimeIdentifier.init(rawValue:)) }
        set { runtimeUsedRaw = newValue?.rawValue }
    }
}
