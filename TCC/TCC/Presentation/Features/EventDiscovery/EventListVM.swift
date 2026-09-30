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
    @Published var selectedDate: Date? = nil
    @Published var freeOnly: Bool = false
    @Published var maxPrice: Decimal? = nil
    @Published var radiusKm: Double? = nil // UI apenas por enquanto, ver nota no chat

    var hasActiveFilters: Bool {
        !selectedCategoryIds.isEmpty || selectedDate != nil || freeOnly || maxPrice != nil
    }

    private let eventRepository: EventRepository
    private let categoryRepository: CategoryRepository

    init(eventRepository: EventRepository, categoryRepository: CategoryRepository) {
        self.eventRepository = eventRepository
        self.categoryRepository = categoryRepository
    }

    var filteredEvents: [Event] {
        events.filter { event in
            guard event.status == .published else { return false }
            let matchesSearch = searchText.isEmpty
                || event.title.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategoryIds.isEmpty
                || event.categories.contains { selectedCategoryIds.contains($0.id) }
            let matchesDate = selectedDate.map {
                Calendar.current.isDate(event.startsAt, inSameDayAs: $0)
            } ?? true
            let matchesPrice: Bool = {
                if freeOnly { return event.price == 0 }
                if let maxPrice { return event.price <= maxPrice }
                return true
            }()
            return matchesSearch && matchesCategory && matchesDate && matchesPrice
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
        selectedDate = nil
        freeOnly = false
        maxPrice = nil
        radiusKm = nil
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
    
    func detailViewModel(for event: Event) -> EventDetailVM {
        EventDetailVM(event: event, repository: eventRepository) { [weak self] updated in
            guard let self, let index = self.events.firstIndex(where: { $0.id == updated.id }) else { return }
            self.events[index] = updated
        }
    }
}
