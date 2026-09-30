
import Foundation

struct Profile: Identifiable {
    let id: UUID
    var displayName: String
    var photoURL: String?
    var role: AccountType
    var updatedAt: Date
    var city: String? = nil
    var state: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
}

enum AccountType: String {
    case attendee
    case producer
}
