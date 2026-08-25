
import SwiftUI

struct Profile: Identifiable {
    let id: UUID
    var displayName: String
    var photoURL: String?
    var role: AccountType
    var updatedAt: Date
}

enum AccountType {
    case attendee
    case producer
}
