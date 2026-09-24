import Foundation

final class UserDefaultsEngagementRepository: EngagementRepository {
    private enum Keys {
        static let localUserId = "localUserId"
        static let favorites = "engagement.favorites"
        static let inscriptions = "engagement.inscriptions"
        static let checkins = "engagement.checkins"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private var localUserId: UUID {
        if let stored = defaults.string(forKey: Keys.localUserId), let id = UUID(uuidString: stored) {
            return id
        }
        let newId = UUID()
        defaults.set(newId.uuidString, forKey: Keys.localUserId)
        return newId
    }

    func addFavorite(eventId: UUID) async throws {
        var favorites = loadFavorites()
        guard !favorites.contains(where: { $0.eventId == eventId }) else { return }
        favorites.append(Favorite(id: UUID(), userId: localUserId, eventId: eventId, savedAt: Date()))
        saveFavorites(favorites)
    }

    func removeFavorite(eventId: UUID) async throws {
        var favorites = loadFavorites()
        favorites.removeAll { $0.eventId == eventId }
        saveFavorites(favorites)
    }

    func markGoing(eventId: UUID) async throws {
        var inscriptions = loadInscriptions()
        guard !inscriptions.contains(where: { $0.eventId == eventId }) else { return }
        inscriptions.append(Inscription(id: UUID(), userId: localUserId, eventId: eventId, registeredAt: Date()))
        saveInscriptions(inscriptions)
    }

    func cancelGoing(eventId: UUID) async throws {
        var inscriptions = loadInscriptions()
        inscriptions.removeAll { $0.eventId == eventId }
        saveInscriptions(inscriptions)
    }

    func checkIn(eventId: UUID) async throws {
        var checkins = loadCheckins()
        guard !checkins.contains(where: { $0.eventId == eventId }) else { return }
        checkins.append(Checkin(id: UUID(), userId: localUserId, eventId: eventId, checkedInAt: Date()))
        saveCheckins(checkins)
    }

    func fetchHistory() async throws -> (favorites: [Favorite], inscriptions: [Inscription], checkins: [Checkin]) {
        (loadFavorites(), loadInscriptions(), loadCheckins())
    }

    private struct StoredEntry: Codable {
        let id: UUID
        let userId: UUID
        let eventId: UUID
        let date: Date
    }

    private func loadFavorites() -> [Favorite] {
        guard let data = defaults.data(forKey: Keys.favorites),
              let entries = try? JSONDecoder().decode([StoredEntry].self, from: data) else { return [] }
        return entries.map { Favorite(id: $0.id, userId: $0.userId, eventId: $0.eventId, savedAt: $0.date) }
    }

    private func saveFavorites(_ favorites: [Favorite]) {
        let entries = favorites.map { StoredEntry(id: $0.id, userId: $0.userId, eventId: $0.eventId, date: $0.savedAt) }
        defaults.set(try? JSONEncoder().encode(entries), forKey: Keys.favorites)
    }

    private func loadInscriptions() -> [Inscription] {
        guard let data = defaults.data(forKey: Keys.inscriptions),
              let entries = try? JSONDecoder().decode([StoredEntry].self, from: data) else { return [] }
        return entries.map { Inscription(id: $0.id, userId: $0.userId, eventId: $0.eventId, registeredAt: $0.date) }
    }

    private func saveInscriptions(_ inscriptions: [Inscription]) {
        let entries = inscriptions.map { StoredEntry(id: $0.id, userId: $0.userId, eventId: $0.eventId, date: $0.registeredAt) }
        defaults.set(try? JSONEncoder().encode(entries), forKey: Keys.inscriptions)
    }

    private func loadCheckins() -> [Checkin] {
        guard let data = defaults.data(forKey: Keys.checkins),
              let entries = try? JSONDecoder().decode([StoredEntry].self, from: data) else { return [] }
        return entries.map { Checkin(id: $0.id, userId: $0.userId, eventId: $0.eventId, checkedInAt: $0.date) }
    }

    private func saveCheckins(_ checkins: [Checkin]) {
        let entries = checkins.map { StoredEntry(id: $0.id, userId: $0.userId, eventId: $0.eventId, date: $0.checkedInAt) }
        defaults.set(try? JSONEncoder().encode(entries), forKey: Keys.checkins)
    }
}
