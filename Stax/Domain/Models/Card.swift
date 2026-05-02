import Foundation
import SwiftData

@Model
final class Card {
    @Attribute(.unique) var id: UUID
    var front: String
    var back: String
    var typeRaw: String
    var difficultyRaw: String

    var sourcePage: Int?
    var sourceSection: String?
    var sourceSnippet: String?

    // SM-2 state
    var easeFactor: Double
    var intervalDays: Int
    var repetitions: Int
    var dueDate: Date
    var lapses: Int
    var suspended: Bool

    var createdAt: Date
    var lastEditedAt: Date?

    var deck: Deck?

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.card)
    var reviews: [ReviewLog] = []

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        type: CardKind,
        difficulty: Difficulty = .medium,
        sourcePage: Int? = nil,
        sourceSection: String? = nil,
        sourceSnippet: String? = nil,
        deck: Deck? = nil
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.typeRaw = type.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.sourcePage = sourcePage
        self.sourceSection = sourceSection
        self.sourceSnippet = sourceSnippet
        self.easeFactor = 2.5
        self.intervalDays = 0
        self.repetitions = 0
        self.dueDate = .now
        self.lapses = 0
        self.suspended = false
        self.createdAt = .now
        self.deck = deck
    }

    var type: CardKind {
        get { CardKind(rawValue: typeRaw) ?? .basic }
        set { typeRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }
}
