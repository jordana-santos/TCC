import Foundation
import Combine

enum EventFormMode {
    case create
    case edit(Event)
}

@MainActor
final class EventFormVM: ObservableObject {
    @Published var title = ""
    @Published var titleTouched = false
    @Published var descriptionText = ""
    @Published var startsAt = Date() {
        didSet { endsAt = endsAt.addingTimeInterval(startsAt.timeIntervalSince(oldValue)) }
    }
    @Published var endsAt = Date()
    @Published var isFree = true
    @Published var priceText = ""
    @Published var isUnlimitedCapacity = true
    @Published var capacity = 100
    @Published var selectedCategoryIds: Set<UUID> = []
    @Published var place: SelectedPlace?

    @Published private(set) var categories: [Category] = []
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let original: Event?
    private let eventRepository: EventRepository
    private let categoryRepository: CategoryRepository

    init(mode: EventFormMode,
         eventRepository: EventRepository,
         categoryRepository: CategoryRepository) {
        self.eventRepository = eventRepository
        self.categoryRepository = categoryRepository

        switch mode {
        case .create:
            original = nil
            let start = Self.nextFullHour()
            startsAt = start
            endsAt = start.addingTimeInterval(2 * 3600)

        case .edit(let event):
            original = event
            title = event.title
            descriptionText = event.description
            startsAt = event.startsAt
            endsAt = event.endsAt
            isFree = event.price == 0
            priceText = event.price == 0 ? "" : Self.priceString(event.price)
            isUnlimitedCapacity = event.capacityMax == nil
            capacity = max(event.capacityMax ?? 100, max(1, event.attendeeCount))
            selectedCategoryIds = Set(event.categories.map(\.id))
            if !event.location.address.isEmpty {
                place = SelectedPlace(address: event.location.address,
                                      latitude: event.location.latitude,
                                      longitude: event.location.longitude)
            }
        }
    }

    var isEditing: Bool { original != nil }
    var originalStatus: EventStatus? { original?.status }
    var originalTitle: String { original?.title ?? "" }
    var attendeeCount: Int { original?.attendeeCount ?? 0 }
    var screenTitle: String { isEditing ? "Editar evento" : "Novo evento" }
    var isDraftFlow: Bool { original == nil || original?.status == .draft }
    var minCapacity: Int { max(1, attendeeCount) }

    var cancelAlertMessage: String {
        if attendeeCount == 0 {
            return "\"\(originalTitle)\" deixará de aparecer para os participantes. Esta ação não pode ser desfeita."
        }
        let who = attendeeCount == 1 ? "1 pessoa inscrita vai" : "\(attendeeCount) pessoas inscritas vão"
        return "\(who) ver \"\(originalTitle)\" como cancelado. Esta ação não pode ser desfeita."
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var showTitleError: Bool {
        titleTouched && trimmedTitle.isEmpty
    }

    var dateError: String? {
        endsAt <= startsAt ? "O fim precisa ser depois do início." : nil
    }

    var parsedPrice: Decimal? {
        if isFree { return 0 }
        let normalized = priceText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized), value > 0 else { return nil }
        return value
    }

    var priceError: String? {
        if isFree || priceText.trimmingCharacters(in: .whitespaces).isEmpty { return nil }
        return parsedPrice == nil ? "Informe um valor válido." : nil
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty
            && dateError == nil
            && parsedPrice != nil
            && place != nil
            && !isSaving
    }

    func loadCategories() async {
        do {
            categories = try await categoryRepository.fetchCategories()
        } catch {
            print("Erro ao carregar categorias:", error)
        }
    }

    func toggleCategory(_ category: Category) {
        if selectedCategoryIds.contains(category.id) {
            selectedCategoryIds.remove(category.id)
        } else {
            selectedCategoryIds.insert(category.id)
        }
    }

    func save(as status: EventStatus, producerId: UUID) async -> Bool {
        guard canSave, let price = parsedPrice, let place else { return false }

        let event = Event(
            id: original?.id ?? UUID(),
            title: trimmedTitle,
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            startsAt: startsAt,
            endsAt: endsAt,
            price: price,
            capacityMax: isUnlimitedCapacity ? nil : capacity,
            attendeeCount: original?.attendeeCount ?? 0,
            externalLink: original?.externalLink,
            imageURL: original?.imageURL,
            status: status,
            producerId: original?.producerId ?? producerId,
            location: Location(address: place.address, latitude: place.latitude, longitude: place.longitude),
            categories: selectedCategories
        )

        return await perform(failureMessage: "Não foi possível salvar o evento. Tente de novo.") {
            if self.isEditing {
                try await self.eventRepository.update(event)
            } else {
                try await self.eventRepository.create(event)
            }
        }
    }

    func cancelEvent() async -> Bool {
        guard let original, original.status == .published else { return false }
        return await perform(failureMessage: "Não foi possível cancelar o evento. Tente de novo.") {
            try await self.eventRepository.setStatus(id: original.id, status: .cancelled)
        }
    }

    func deleteEvent() async -> Bool {
        guard let original, original.status == .draft else { return false }
        return await perform(failureMessage: "Não foi possível excluir o evento. Tente de novo.") {
            try await self.eventRepository.delete(id: original.id)
        }
    }

    private var selectedCategories: [Category] {
        var seen = Set<UUID>()
        return (categories + (original?.categories ?? []))
            .filter { selectedCategoryIds.contains($0.id) && seen.insert($0.id).inserted }
    }

    private func perform(failureMessage: String, _ work: () async throws -> Void) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await work()
            return true
        } catch {
            print("Erro no formulário de evento:", error)
            errorMessage = Self.message(for: error, fallback: failureMessage)
            return false
        }
    }

    private static func message(for error: Error, fallback: String) -> String {
        if "\(error)".contains("capacity_below_attendees") {
            return "A capacidade não pode ser menor que o número de inscritos."
        }
        return fallback
    }

    private static func priceString(_ price: Decimal) -> String {
        String(format: "%.2f", (price as NSDecimalNumber).doubleValue)
            .replacingOccurrences(of: ".", with: ",")
    }

    private static func nextFullHour() -> Date {
        Calendar.current.dateInterval(of: .hour, for: Date())?.end ?? Date().addingTimeInterval(3600)
    }
}
