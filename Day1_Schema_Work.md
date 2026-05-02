# Day 1: SwiftData Schema

Foundation for everything else. Replace the `Item` placeholder with the real domain model and verify the app still launches.

## Checklist

- [ ] Create `Stax/Domain/Models/` folder
- [ ] Create `Stax/Domain/Models/Document.swift`
- [ ] Create `Stax/Domain/Models/Deck.swift`
- [ ] Create `Stax/Domain/Models/Card.swift`
- [ ] Create `Stax/Domain/Models/ReviewLog.swift`
- [ ] Create `Stax/Domain/Enums.swift`
- [ ] Create `Stax/Storage/PersistenceController.swift` (wraps `SchemaV1` + `ModelContainer`)
- [ ] Modify `Stax/StaxApp.swift` — swap `Item.self` for the four new types via `PersistenceController`
- [ ] Modify `Stax/ContentView.swift` — gut the `Item` UI, leave a placeholder that shows deck count from a `@Query`
- [ ] Delete `Stax/Item.swift`
- [ ] Build (⌘B) — must succeed
- [ ] Run on simulator — must launch and show the placeholder without crashing

## Files

### `Stax/Domain/Enums.swift`

```swift
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
```

### `Stax/Domain/Models/Document.swift`

```swift
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
```

### `Stax/Domain/Models/Deck.swift`

```swift
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
```

### `Stax/Domain/Models/Card.swift`

```swift
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
```

### `Stax/Domain/Models/ReviewLog.swift`

```swift
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
```

### `Stax/Storage/PersistenceController.swift`

Versioned from day one so a v2 migration isn't a rewrite.

```swift
import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] {
        [Document.self, Deck.self, Card.self, ReviewLog.self]
    }
}

enum PersistenceController {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

### `Stax/StaxApp.swift` — replace whole file

```swift
import SwiftData
import SwiftUI

@main
struct StaxApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try PersistenceController.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

### `Stax/ContentView.swift` — replace whole file

Placeholder until `LibraryView` lands. Proves the schema is wired and queryable.

```swift
import SwiftData
import SwiftUI

struct ContentView: View {
    @Query private var decks: [Deck]

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No decks yet",
                systemImage: "rectangle.stack",
                description: Text("Imported decks will appear here. (\(decks.count) so far.)")
            )
            .navigationTitle("Stax")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SchemaV1.models, inMemory: true)
}
```

## Verification

1. `xcodebuild -project Stax.xcodeproj -scheme Stax -destination 'generic/platform=iOS Simulator' build` → `BUILD SUCCEEDED`
2. Run on a simulator. App launches without crashing, shows the empty-state placeholder.
3. Quick sanity in `#Preview`: it renders.
4. (Optional) Add a one-shot test in `StaxTests` that constructs each model with sample data and calls `context.save()` against an in-memory container — proves relationships and unique constraints work before any UI uses them.

## Notes / gotchas

- `@Relationship(deleteRule: .cascade, inverse:)` must be declared on **one side only** — kept on the parent (Document / Deck / Card) to mirror the ownership direction.
- Enums stored as `String` raw values, not as `@Attribute(.transformable)`, so SwiftData migrations stay simple.
- `Schema.Version(1, 0, 0)` lets us bump to `1, 1, 0` for additive changes (new optional fields) without a migration plan; reserve `2, 0, 0` for breaking changes.
- `inMemory: true` path is for tests/previews; production goes through the default disk-backed configuration.
- Don't add `@Transient` computed helpers (e.g. cloze parsing) to `@Model` types yet — keep models data-only until UI needs prove the shape.
