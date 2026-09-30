import Foundation
import Combine

@MainActor
final class EngagementStore: ObservableObject {
    @Published private(set) var favoritedEventIds: Set<UUID> = []
    @Published private(set) var goingEventIds: Set<UUID> = []
    @Published private(set) var checkedInEventIds: Set<UUID> = []

    private let repository: EngagementRepository

    init(repository: EngagementRepository? = nil) {
        self.repository = repository ?? SupabaseEngagementRepository()
    }

    func isFavorited(_ eventId: UUID) -> Bool { favoritedEventIds.contains(eventId) }
    func isGoing(_ eventId: UUID) -> Bool { goingEventIds.contains(eventId) }
    func hasCheckedIn(_ eventId: UUID) -> Bool { checkedInEventIds.contains(eventId) }

    func toggleFavorite(_ eventId: UUID) {
        let already = favoritedEventIds.contains(eventId)
        if already { favoritedEventIds.remove(eventId) } else { favoritedEventIds.insert(eventId) }
        Task {
            do {
                if already {
                    try await repository.removeFavorite(eventId: eventId)
                } else {
                    try await repository.addFavorite(eventId: eventId)
                }
            } catch {
                if already { favoritedEventIds.insert(eventId) } else { favoritedEventIds.remove(eventId) }
            }
        }
    }

    func toggleGoing(_ event: Event) async -> Bool {
        let eventId = event.id
        let already = goingEventIds.contains(eventId)
        if !already && event.isFull { return false }

        if already { goingEventIds.remove(eventId) } else { goingEventIds.insert(eventId) }
        do {
            if already {
                try await repository.cancelGoing(eventId: eventId)
            } else {
                try await MarkGoing(repository: repository).execute(event: event)
            }
            return true
        } catch {
            if already { goingEventIds.insert(eventId) } else { goingEventIds.remove(eventId) }
            return false
        }
    }

    func checkIn(_ eventId: UUID) {
        guard !checkedInEventIds.contains(eventId) else { return }
        checkedInEventIds.insert(eventId)
        Task {
            do {
                try await repository.checkIn(eventId: eventId)
            } catch {
                checkedInEventIds.remove(eventId)
            }
        }
    }

    func loadHistory() async {
        if let history = try? await repository.fetchHistory() {
            favoritedEventIds.formUnion(history.favorites.map { $0.eventId })
            goingEventIds.formUnion(history.inscriptions.map { $0.eventId })
            checkedInEventIds.formUnion(history.checkins.map { $0.eventId })
        }
    }

    func clear() {
        favoritedEventIds = []
        goingEventIds = []
        checkedInEventIds = []
    }
}
