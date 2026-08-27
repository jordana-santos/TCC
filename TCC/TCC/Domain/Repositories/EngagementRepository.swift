
import Foundation

protocol EngagementRepository {
    func addFavorite(eventId: UUID) async throws
    func removeFavorite(eventId: UUID) async throws
    func markGoing(eventId: UUID) async throws
    func cancelGoing(eventId: UUID) async throws
    func checkIn(eventId: UUID) async throws
    func fetchHistory() async throws -> (favorites: [Favorite], inscriptions: [Inscription], checkins: [Checkin])
}
