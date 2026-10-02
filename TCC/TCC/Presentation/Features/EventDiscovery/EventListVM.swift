import Foundation
import Combine
import CoreLocation

enum ReferenceState {
    case resolving
    case available
    case needsCity
}

enum ReferenceSource {
    case manual
    case device
    case profile
    case savedCity
    case none
}

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
    @Published var radiusKm: Double = 50

    @Published private(set) var referenceState: ReferenceState = .resolving
    @Published private(set) var referenceSource: ReferenceSource = .none
    @Published private(set) var referenceCoordinate: CLLocationCoordinate2D?
    @Published private(set) var referenceLabel: String?

    private var manualPlace: CityPlace?          
    private var deviceLocation: CLLocationCoordinate2D?
    private var isLocationPending = true
    private var profilePlace: CityPlace?
    private var savedPlace: CityPlace? = SavedCityStore.load()

    var hasActiveFilters: Bool {
        !selectedCategoryIds.isEmpty || selectedDate != nil || freeOnly || maxPrice != nil
    }
    var suggestedState: String {
            manualPlace?.state ?? profilePlace?.state ?? savedPlace?.state ?? "AC"
        }
    private let eventRepository: EventRepository
    private let categoryRepository: CategoryRepository

    init(eventRepository: EventRepository, categoryRepository: CategoryRepository) {
        self.eventRepository = eventRepository
        self.categoryRepository = categoryRepository
    }

    var baseFilteredEvents: [Event] {
        let now = Date()
        return events.filter { event in
            guard event.status == .published, event.endsAt >= now else { return false }
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

    var filteredEvents: [Event] {
        guard let origin = referenceCoordinate else { return [] }
        let center = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let limit = radiusKm * 1000
        return baseFilteredEvents.filter { event in
            let target = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
            return target.distance(from: center) <= limit
        }
    }

    func updateReference(deviceLocation: CLLocationCoordinate2D?, isLocationPending: Bool, profile: Profile?) {
        self.deviceLocation = deviceLocation
        self.isLocationPending = isLocationPending
        if let profile, let city = profile.city, let state = profile.state,
           let latitude = profile.latitude, let longitude = profile.longitude {
            profilePlace = CityPlace(city: city, state: state, latitude: latitude, longitude: longitude)
        } else {
            profilePlace = nil
        }
        recomputeReference()
    }

    func setCity(city: String, state: String) async throws {
        let coordinate = try await CityGeocoder.coordinate(city: city, state: state)
        let place = CityPlace(city: city, state: state,
                              latitude: coordinate.latitude, longitude: coordinate.longitude)
        SavedCityStore.save(place)
        savedPlace = place
        manualPlace = place
        recomputeReference()
    }

    private func recomputeReference() {
        if let place = manualPlace {
            apply(.available, .manual, place.coordinate, place.label)
        } else if let deviceLocation {
            apply(.available, .device, deviceLocation, "Sua localização atual")
        } else if isLocationPending {
            apply(.resolving, .none, nil, nil)
        } else if let place = profilePlace {
            apply(.available, .profile, place.coordinate, place.label)
        } else if let place = savedPlace {
            apply(.available, .savedCity, place.coordinate, place.label)
        } else {
            apply(.needsCity, .none, nil, nil)
        }
    }

    private func apply(_ state: ReferenceState, _ source: ReferenceSource,
                       _ coordinate: CLLocationCoordinate2D?, _ label: String?) {
        referenceState = state
        referenceSource = source
        referenceCoordinate = coordinate
        referenceLabel = label
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
        radiusKm = 50
        manualPlace = nil
        savedPlace = nil
        SavedCityStore.clear()
        recomputeReference()
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
            print("Erro ao carregar eventos:", error)
            errorMessage = "Não foi possível carregar os eventos."
        }
    }
    
    func refresh() async {
            guard !isLoading else { return }
            if events.isEmpty {
                await load()
                return
            }
            do {
                events = try await eventRepository.fetchEvents(filter: .none)
            } catch {
                print("Erro ao atualizar eventos:", error)
            }
        }

    func detailViewModel(for event: Event) -> EventDetailVM {
        EventDetailVM(event: event, repository: eventRepository) { [weak self] updated in
            guard let self, let index = self.events.firstIndex(where: { $0.id == updated.id }) else { return }
            self.events[index] = updated
        }
    }
}
