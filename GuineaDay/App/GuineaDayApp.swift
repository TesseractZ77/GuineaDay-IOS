import SwiftUI
import SwiftData
import FirebaseCore

@main
struct GuineaDayApp: App {
    
    // Configure Firebase as early as possible
    init() {
        FirebaseApp.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([TaskItem.self, GuineaPig.self, WeightLog.self, Photo.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)  // ← force light mode app-wide
        }
        .modelContainer(sharedModelContainer)
    }

}
