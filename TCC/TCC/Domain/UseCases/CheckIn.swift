import Foundation

struct CheckIn {
    let repository: EngagementRepository

    func execute(eventId: UUID, existingInscriptions: [Inscription]) async throws {
        guard existingInscriptions.contains(where: { $0.eventId == eventId }) else {
            throw EventError.mustBeGoingToCheckIn
        }
        try await repository.checkIn(eventId: eventId)
    }
}
