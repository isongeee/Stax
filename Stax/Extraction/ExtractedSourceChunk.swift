import Foundation

struct ExtractedSourceChunk: Equatable, Sendable {
    let sourceIndex: Int
    let sourceTitle: String?
    let text: String
}
