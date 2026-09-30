
import Foundation

struct ProfileDTO: Codable {
    let id: UUID
    let displayName: String
    let photoURL: String?
    let role: String
    let updatedAt: Date
    let city: String?
    let state: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, role, city, state, latitude, longitude
        case displayName = "display_name"
        case photoURL = "photo_url"
        case updatedAt = "updated_at"
    }

    func toEntity() -> Profile {
        Profile(id: id, displayName: displayName, photoURL: photoURL,
                role: AccountType(rawValue: role) ?? .attendee, updatedAt: updatedAt,
                city: city, state: state, latitude: latitude, longitude: longitude)
    }
}
