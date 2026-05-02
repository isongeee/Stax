import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 1, 0) }
    static var models: [any PersistentModel.Type] {
        [Document.self, Deck.self, Card.self, ReviewLog.self, SourceChunk.self]
    }
}

enum PersistenceController {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            #if DEBUG
            guard !inMemory else { throw error }
            try resetStore(at: config.url)
            return try ModelContainer(for: schema, configurations: [config])
            #else
            throw error
            #endif
        }
    }

    #if DEBUG
    private static func resetStore(at url: URL) throws {
        let fileManager = FileManager.default
        let urls = [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal")
        ]

        for url in urls where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    #endif
}
