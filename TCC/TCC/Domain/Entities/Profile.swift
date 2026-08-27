
import Foundation

struct Profile: Identifiable {
    let id: UUID
    var displayName: String
    var photoURL: String?
    var role: AccountType
    var updatedAt: Date
}

enum AccountType: String {
    case attendee
    case producer
}
