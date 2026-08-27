
import Foundation

struct Event: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var startsAt: Date
    var endsAt: Date
    var price: Decimal
    var capacityMax: Int?
    var attendeeCount: Int
    var externalLink: String?
    var imageURL: String?
    var status: EventStatus
    var producerId: UUID
    var location: Location
    var categories: [Category]

    var remainingCapacity: Int? {
        guard let capacityMax else { return nil }
        return capacityMax - attendeeCount
    }

    var isFull: Bool {
        guard let capacityMax else { return false }
        return attendeeCount >= capacityMax
    }
}

enum EventStatus: String {
    case draft
    case published
    case cancelled
}

struct Location {
    var address: String
    var latitude: Double
    var longitude: Double
}
