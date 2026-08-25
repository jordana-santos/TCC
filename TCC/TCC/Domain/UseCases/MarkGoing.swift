
import SwiftUI

struct MarkGoing {
    let repository: EngagementRepository

    func execute(event: Event) async throws {
        guard !event.isFull else {
            throw EventError.full
        }
        try await repository.markGoing(eventId: event.id)
    }
}
