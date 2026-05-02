import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SchemaV1.models, inMemory: true)
}
