import Foundation
import Combine

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favoritedEventIds: Set<UUID> = []

    private let repository: EngagementRepository

    init(repository: EngagementRepository = UserDefaultsEngagementRepository()) {
        self.repository = repository
        Task { await loadFavorites() }
    }

    func isFavorited(_ eventId: UUID) -> Bool {
        favoritedEventIds.contains(eventId)
    }

    func toggleFavorite(_ eventId: UUID) {
        let alreadyFavorited = favoritedEventIds.contains(eventId)
        if alreadyFavorited {
            favoritedEventIds.remove(eventId)
        } else {
            favoritedEventIds.insert(eventId)
        }

        Task {
            do {
                if alreadyFavorited {
                    try await repository.removeFavorite(eventId: eventId)
                } else {
                    try await repository.addFavorite(eventId: eventId)
                }
            } catch {
                await loadFavorites()
            }
        }
    }

    private func loadFavorites() async {
        if let history = try? await repository.fetchHistory() {
            favoritedEventIds = Set(history.favorites.map { $0.eventId })
        }
    }
}
