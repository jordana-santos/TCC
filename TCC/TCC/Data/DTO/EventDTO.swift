
import Foundation

struct LocationDTO: Codable {
    let address: String
    let latitude: Double
    let longitude: Double

    func toEntity() -> Location {
        Location(address: address, latitude: latitude, longitude: longitude)
    }
}

struct EventCategoryLinkDTO: Codable {
    let category: CategoryDTO
    enum CodingKeys: String, CodingKey { case category = "categories" }
}

struct EventDTO: Codable {
    let id: UUID
    let title: String
    let description: String?
    let startsAt: Date
    let endsAt: Date
    let price: Decimal
    let capacityMax: Int?
    let attendeeCount: Int
    let externalLink: String?
    let imageURL: String?
    let status: String
    let producerId: UUID
    let locations: [LocationDTO]
    let eventCategories: [EventCategoryLinkDTO]

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, status, locations
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case capacityMax = "capacity_max"
        case attendeeCount = "attendee_count"
        case externalLink = "external_link"
        case imageURL = "image_url"
        case producerId = "producer_id"
        case eventCategories = "event_categories"
    }

    func toEntity() -> Event {
        Event(id: id, title: title, description: description ?? "",
              startsAt: startsAt, endsAt: endsAt, price: price,
              capacityMax: capacityMax, attendeeCount: attendeeCount,
              externalLink: externalLink, imageURL: imageURL,
              status: EventStatus(rawValue: status) ?? .draft,
              producerId: producerId,
              location: locations.first?.toEntity() ?? Location(address: "", latitude: 0, longitude: 0),
              categories: eventCategories.map { $0.category.toEntity() })
    }
}
