import Foundation
import SwiftData

@Model
final class Document {
    @Attribute(.unique) var id: UUID
    var title: String
    var fileBookmark: Data
    var sourceKindRaw: String
    var pageOrSlideCount: Int
    var importedAt: Date
    var ocrUsed: Bool

    @Relationship(deleteRule: .cascade, inverse: \Deck.document)
    var decks: [Deck] = []

    init(
        id: UUID = UUID(),
        title: String,
        fileBookmark: Data,
        sourceKind: SourceKind,
        pageOrSlideCount: Int,
        ocrUsed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.fileBookmark = fileBookmark
        self.sourceKindRaw = sourceKind.rawValue
        self.pageOrSlideCount = pageOrSlideCount
        self.importedAt = .now
        self.ocrUsed = ocrUsed
    }

    var sourceKind: SourceKind {
        get { SourceKind(rawValue: sourceKindRaw) ?? .pdf }
        set { sourceKindRaw = newValue.rawValue }
    }
}
