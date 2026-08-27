
import Foundation

struct FavoriteDTO: Codable {
    let id: UUID; let userId: UUID; let eventId: UUID; let savedAt: Date
    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case eventId = "event_id"; case savedAt = "saved_at"
    }
    func toEntity() -> Favorite { Favorite(id: id, userId: userId, eventId: eventId, savedAt: savedAt) }
}

struct InscriptionDTO: Codable {
    let id: UUID; let userId: UUID; let eventId: UUID; let registeredAt: Date
    enum CodingKeys: String, CodingKey {
        case id; case userId = "user_id"; case eventId = "event_id"; case registeredAt = "registered_at"
    }
    func toEntity() -> Inscription { Inscription(id: id, userId: userId, eventId: eventId, registeredAt: registeredAt) }
}

struct CheckinDTO: Codable {
    let id: UUID; let userId: UUID; let eventId: UUID; let checkedInAt: Date; let method: String
    enum CodingKeys: String, CodingKey {
        case id, method; case userId = "user_id"; case eventId = "event_id"; case checkedInAt = "checked_in_at"
    }
    func toEntity() -> Checkin { Checkin(id: id, userId: userId, eventId: eventId, checkedInAt: checkedInAt) }
}
