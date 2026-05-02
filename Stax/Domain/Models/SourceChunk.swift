import Foundation
import SwiftData

@Model
final class SourceChunk {
    @Attribute(.unique) var id: UUID
    var sourceIndex: Int
    var sourceTitle: String?
    var text: String
    var createdAt: Date

    var document: Document?

    init(
        id: UUID = UUID(),
        sourceIndex: Int,
        sourceTitle: String? = nil,
        text: String,
        document: Document? = nil
    ) {
        self.id = id
        self.sourceIndex = sourceIndex
        self.sourceTitle = sourceTitle
        self.text = text
        self.createdAt = .now
        self.document = document
    }
}
