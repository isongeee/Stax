import Foundation
import SwiftData

@Model
final class ReviewLog {
    @Attribute(.unique) var id: UUID
    var reviewedAt: Date
    var grade: Int
    var prevInterval: Int
    var newInterval: Int

    var card: Card?

    init(
        id: UUID = UUID(),
        grade: Int,
        prevInterval: Int,
        newInterval: Int,
        card: Card? = nil
    ) {
        self.id = id
        self.reviewedAt = .now
        self.grade = grade
        self.prevInterval = prevInterval
        self.newInterval = newInterval
        self.card = card
    }
}
