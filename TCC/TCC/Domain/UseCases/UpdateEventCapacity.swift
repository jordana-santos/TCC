import Foundation

struct UpdateEventCapacity {
    let repository: EventRepository

    func execute(event: Event, newCapacity: Int?) async throws {
        if let newCapacity, newCapacity < event.attendeeCount {
            throw EventError.capacityBelowAttendees
        }
        var updated = event
        updated.capacityMax = newCapacity
        try await repository.update(updated)
    }
}
