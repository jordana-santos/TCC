
import Foundation

struct EventFilter {
    var categoryId: UUID?
    var startDate: Date?
    var endDate: Date?
    var maxPrice: Decimal?

    static let none = EventFilter()
}

protocol EventRepository {
    func fetchEvents(filter: EventFilter) async throws -> [Event]
    func fetchEvent(id: UUID) async throws -> Event
    func create(_ event: Event) async throws
    func update(_ event: Event) async throws
    func delete(id: UUID) async throws
    func fetchProducerEvents(producerId: UUID) async throws -> [Event]
    func setStatus(id: UUID, status: EventStatus) async throws
}
