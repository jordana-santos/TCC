import SwiftUI
import SwiftData

@main
struct TCCApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            EventListView(
                viewModel: EventListVM(
                    eventRepository: SupabaseEventRepository(),
                    categoryRepository: SupabaseCategoryRepository()
                )
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
