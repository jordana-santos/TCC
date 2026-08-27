import Foundation
import Supabase


final class SupabaseEventRepository: EventRepository {
    private let dataSource = EventDS()

    func fetchEvents(filter: EventFilter) async throws -> [Event] {
        try await dataSource.fetchEvents(filter: filter).map { $0.toEntity() }
    }
    
    func fetchEvent(id: UUID) async throws -> Event {
        try await dataSource.fetchEvent(id: id).toEntity()
    }
    func create(_ event: Event) async throws {
        let payload = Self.payload(from: event)
        let newId = try await dataSource.insertEvent(payload)
        try await dataSource.insertLocation(eventId: newId, address: event.location.address,
                                             latitude: event.location.latitude, longitude: event.location.longitude)
        try await dataSource.setCategories(eventId: newId, categoryIds: event.categories.map(\.id))
    }
    func update(_ event: Event) async throws {
        try await dataSource.updateEvent(id: event.id, payload: Self.payload(from: event))
        try await dataSource.setCategories(eventId: event.id, categoryIds: event.categories.map(\.id))
    }
    func delete(id: UUID) async throws {
        try await dataSource.deleteEvent(id: id)
    }

    private static func payload(from event: Event) -> EventWritePayload {
        EventWritePayload(title: event.title, description: event.description, startsAt: event.startsAt,
                           endsAt: event.endsAt, price: event.price, capacityMax: event.capacityMax,
                           externalLink: event.externalLink, imageURL: event.imageURL,
                           status: event.status.rawValue, producerId: event.producerId)
    }
}
