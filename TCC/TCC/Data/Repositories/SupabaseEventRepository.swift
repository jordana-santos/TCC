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
        let description = event.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let params = CreateEventParams(
            title: event.title,
            description: description.isEmpty ? nil : description,
            startsAt: event.startsAt,
            endsAt: event.endsAt,
            price: event.price,
            capacityMax: event.capacityMax,
            externalLink: event.externalLink,
            imageURL: event.imageURL,
            status: event.status.rawValue,
            address: event.location.address,
            latitude: event.location.latitude,
            longitude: event.location.longitude,
            categoryIds: event.categories.map(\.id)
        )
        _ = try await dataSource.createEventFull(params)
    }
    
    func update(_ event: Event) async throws {
        let description = event.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let params = UpdateEventParams(
            eventId: event.id,
            title: event.title,
            description: description.isEmpty ? nil : description,
            startsAt: event.startsAt,
            endsAt: event.endsAt,
            price: event.price,
            capacityMax: event.capacityMax,
            externalLink: event.externalLink,
            imageURL: event.imageURL,
            status: event.status.rawValue,
            address: event.location.address,
            latitude: event.location.latitude,
            longitude: event.location.longitude,
            categoryIds: event.categories.map(\.id)
        )
        try await dataSource.updateEventFull(params)
    }
    
    func delete(id: UUID) async throws {
        try await dataSource.deleteEvent(id: id)
    }

    private static func payload(from event: Event) -> EventWritePayload {
        EventWritePayload(
            title: event.title,
            description: event.description,
            startsAt: event.startsAt,
            endsAt: event.endsAt,
            price: event.price,
            capacityMax: event.capacityMax,
            externalLink: event.externalLink,
            imageURL: event.imageURL,
            status: event.status.rawValue,
            producerId: event.producerId)
    }
    
    func fetchProducerEvents(producerId: UUID) async throws -> [Event] {
        try await dataSource.fetchProducerEvents(producerId: producerId).map { $0.toEntity() }
    }
    
    func setStatus(id: UUID, status: EventStatus) async throws {
        try await dataSource.updateStatus(id: id, status: status.rawValue)
    }
}
