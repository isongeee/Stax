import Foundation

enum BookmarkResolver {
    nonisolated static func withResolvedURL<T>(
        title: String,
        fileBookmark: Data,
        _ body: (URL) throws -> T
    ) throws -> T {
        var isStale = false
        let url: URL

        do {
            url = try URL(
                resolvingBookmarkData: fileBookmark,
                options: [.withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            throw ExtractionError.unreadableBookmark(title)
        }

        guard !isStale else {
            throw ExtractionError.staleBookmark(title)
        }

        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        return try body(url)
    }
}
