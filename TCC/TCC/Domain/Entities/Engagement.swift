
import SwiftUI

struct Favorite: Identifiable {
    let id: UUID
    let userId: UUID
    let eventId: UUID
    let savedAt: Date
}

struct Inscription: Identifiable {
    let id: UUID
    let userId: UUID
    let eventId: UUID
    let registeredAt: Date
}

struct Checkin: Identifiable {
    let id: UUID
    let userId: UUID
    let eventId: UUID
    let checkedInAt: Date
}
