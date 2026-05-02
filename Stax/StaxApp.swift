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
