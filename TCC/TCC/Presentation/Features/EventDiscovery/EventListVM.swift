import Foundation
import Combine

@MainActor
final class EventListVM: ObservableObject {
    @Published var events: [Event] = []
    @Published var categories: [Category] = []
    @Published var searchText: String = ""
    @Published var selectedCategoryIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let eventRepository: EventRepository
    private let categoryRepository: CategoryRepository

    init(eventRepository: EventRepository, categoryRepository: CategoryRepository) {
        self.eventRepository = eventRepository
        self.categoryRepository = categoryRepository
    }

    var filteredEvents: [Event] {
        events.filter { event in
            let matchesSearch = searchText.isEmpty
                || event.title.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategoryIds.isEmpty
                || event.categories.contains { selectedCategoryIds.contains($0.id) }
            return matchesSearch && matchesCategory
        }
    }

    func toggleCategory(_ category: Category) {
        if selectedCategoryIds.contains(category.id) {
            selectedCategoryIds.remove(category.id)
        } else {
            selectedCategoryIds.insert(category.id)
        }
    }

    func clearFilters() {
        selectedCategoryIds.removeAll()
        searchText = ""
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        async let eventsResult = eventRepository.fetchEvents(filter: .none)
        async let categoriesResult = categoryRepository.fetchCategories()
        do {
            let (fetchedEvents, fetchedCategories) = try await (eventsResult, categoriesResult)
            events = fetchedEvents
            categories = fetchedCategories
        } catch {
            errorMessage = "Não foi possível carregar os eventos."
        }
    }
}
