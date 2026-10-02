
import Foundation
import Supabase

enum DataError: Error { case missingID }

struct EventWritePayload: Encodable {
    let title: String; let description: String?; let startsAt: Date; let endsAt: Date
    let price: Decimal; let capacityMax: Int?; let externalLink: String?
    let imageURL: String?; let status: String; let producerId: UUID

    enum CodingKeys: String, CodingKey {
        case title, description, price, status
        case startsAt = "starts_at", endsAt = "ends_at", capacityMax = "capacity_max"
        case externalLink = "external_link", imageURL = "image_url", producerId = "producer_id"
    }
}

struct CreateEventParams: Encodable {
    let title: String
    let description: String?
    let startsAt: Date
    let endsAt: Date
    let price: Decimal
    let capacityMax: Int?
    let externalLink: String?
    let imageURL: String?
    let status: String
    let address: String
    let latitude: Double
    let longitude: Double
    let categoryIds: [UUID]

    enum CodingKeys: String, CodingKey {
        case title = "p_title", description = "p_description"
        case startsAt = "p_starts_at", endsAt = "p_ends_at"
        case price = "p_price", capacityMax = "p_capacity_max"
        case externalLink = "p_external_link", imageURL = "p_image_url"
        case status = "p_status", address = "p_address"
        case latitude = "p_latitude", longitude = "p_longitude"
        case categoryIds = "p_category_ids"
    }
}

struct UpdateEventParams: Encodable {
    let eventId: UUID
    let title: String
    let description: String?
    let startsAt: Date
    let endsAt: Date
    let price: Decimal
    let capacityMax: Int?
    let externalLink: String?
    let imageURL: String?
    let status: String
    let address: String
    let latitude: Double
    let longitude: Double
    let categoryIds: [UUID]

    enum CodingKeys: String, CodingKey {
        case eventId = "p_event_id"
        case title = "p_title", description = "p_description"
        case startsAt = "p_starts_at", endsAt = "p_ends_at"
        case price = "p_price", capacityMax = "p_capacity_max"
        case externalLink = "p_external_link", imageURL = "p_image_url"
        case status = "p_status", address = "p_address"
        case latitude = "p_latitude", longitude = "p_longitude"
        case categoryIds = "p_category_ids"
    }
}

final class EventDS {
    private let client = SupabaseManager.shared
    private let embed = "*, locations(*), event_categories(categories(*))"

    func fetchEvents(filter: EventFilter) async throws -> [EventDTO] {
        let needsCategoryJoin = filter.categoryId != nil
        var query = client.from("events")
            .select(needsCategoryJoin
                ? "*, locations(*), event_categories!inner(categories(*))"
                : "*, locations(*), event_categories(categories(*))")
            .eq("status", value: "published")

        if let categoryId = filter.categoryId {
            query = query.eq("event_categories.category_id", value: categoryId)
        }
        if let startDate = filter.startDate {
            query = query.gte("starts_at", value: startDate)
        }
        if let endDate = filter.endDate {
            query = query.lte("starts_at", value: endDate)
        }
        if let maxPrice = filter.maxPrice {
            query = query.lte("price", value: (maxPrice as NSDecimalNumber).doubleValue)
        }

        return try await query.execute().value
    }

    func fetchEvent(id: UUID) async throws -> EventDTO {
        try await client.from("events").select(embed).eq("id", value: id).single().execute().value
    }

    func insertEvent(_ payload: EventWritePayload) async throws -> UUID {
        struct InsertedID: Decodable { let id: UUID }
        let result: [InsertedID] = try await client.from("events")
            .insert(payload).select("id").execute().value
        guard let id = result.first?.id else { throw DataError.missingID }
        return id
    }

    func updateEvent(id: UUID, payload: EventWritePayload) async throws {
        try await client.from("events").update(payload).eq("id", value: id).execute()
    }

    func deleteEvent(id: UUID) async throws {
        try await client.from("events").delete().eq("id", value: id).execute()
    }

    func insertLocation(eventId: UUID, address: String, latitude: Double, longitude: Double) async throws {
        struct Payload: Encodable {
            let eventId: UUID; let address: String; let latitude: Double; let longitude: Double
            enum CodingKeys: String, CodingKey { case eventId = "event_id", address, latitude, longitude }
        }
        try await client.from("locations")
            .insert(Payload(eventId: eventId, address: address, latitude: latitude, longitude: longitude))
            .execute()
    }

    func setCategories(eventId: UUID, categoryIds: [UUID]) async throws {
        try await client.from("event_categories").delete().eq("event_id", value: eventId).execute()
        struct Link: Encodable {
            let eventId: UUID; let categoryId: UUID
            enum CodingKeys: String, CodingKey { case eventId = "event_id", categoryId = "category_id" }
        }
        try await client.from("event_categories").insert(categoryIds.map { Link(eventId: eventId, categoryId: $0) }).execute()
    }
    
    func fetchProducerEvents(producerId: UUID) async throws -> [EventDTO] {
        try await client.from("events")
            .select(embed)
            .eq("producer_id", value: producerId)
            .execute().value
    }
    
    func createEventFull(_ params: CreateEventParams) async throws -> UUID {
        try await client.rpc("create_event_full", params: params).execute().value
    }
    
    func updateEventFull(_ params: UpdateEventParams) async throws {
        try await client.rpc("update_event_full", params: params).execute()
    }

    func updateStatus(id: UUID, status: String) async throws {
        struct Payload: Encodable { let status: String }
        struct Row: Decodable { let id: UUID }
        let rows: [Row] = try await client.from("events")
            .update(Payload(status: status))
            .eq("id", value: id)
            .select("id")
            .execute().value
        guard !rows.isEmpty else { throw DataError.missingID }
    }
}
