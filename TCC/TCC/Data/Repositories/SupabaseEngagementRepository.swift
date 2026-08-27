import Foundation
import Supabase

final class SupabaseEngagementRepository: EngagementRepository {
    private let dataSource = EngagementDS()
    private let client = SupabaseManager.shared

    private var currentUserId: UUID { get async throws { try await client.auth.session.user.id } }

    func addFavorite(eventId: UUID) async throws {
        try await dataSource.addFavorite(userId: try await currentUserId, eventId: eventId)
    }
    func removeFavorite(eventId: UUID) async throws {
        try await dataSource.removeFavorite(userId: try await currentUserId, eventId: eventId)
    }
    func markGoing(eventId: UUID) async throws {
        try await dataSource.markGoing(userId: try await currentUserId, eventId: eventId)
    }
    func cancelGoing(eventId: UUID) async throws {
        try await dataSource.cancelGoing(userId: try await currentUserId, eventId: eventId)
    }
    func checkIn(eventId: UUID) async throws {
        try await dataSource.checkIn(userId: try await currentUserId, eventId: eventId)
    }
    func fetchHistory() async throws -> (favorites: [Favorite], inscriptions: [Inscription], checkins: [Checkin]) {
        let userId = try await currentUserId
        async let f = dataSource.fetchFavorites(userId: userId)
        async let i = dataSource.fetchInscriptions(userId: userId)
        async let c = dataSource.fetchCheckins(userId: userId)
        let (favs, inscs, checks) = try await (f, i, c)
        return (favs.map { $0.toEntity() }, inscs.map { $0.toEntity() }, checks.map { $0.toEntity() })
    }
}
