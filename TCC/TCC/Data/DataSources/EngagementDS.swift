
import Foundation
import Supabase

private struct EngagementLink: Encodable {
    let userId: UUID; let eventId: UUID
    enum CodingKeys: String, CodingKey { case userId = "user_id", eventId = "event_id" }
}

final class EngagementDS {
    private let client = SupabaseManager.shared

    func addFavorite(userId: UUID, eventId: UUID) async throws {
        try await client.from("favorites").insert(EngagementLink(userId: userId, eventId: eventId)).execute()
    }
    func removeFavorite(userId: UUID, eventId: UUID) async throws {
        try await client.from("favorites").delete().eq("user_id", value: userId).eq("event_id", value: eventId).execute()
    }
    func markGoing(userId: UUID, eventId: UUID) async throws {
        try await client.from("inscriptions").insert(EngagementLink(userId: userId, eventId: eventId)).execute()
    }
    func cancelGoing(userId: UUID, eventId: UUID) async throws {
        try await client.from("inscriptions").delete().eq("user_id", value: userId).eq("event_id", value: eventId).execute()
    }
    func checkIn(userId: UUID, eventId: UUID) async throws {
        try await client.from("checkins").insert(EngagementLink(userId: userId, eventId: eventId)).execute()
    }
    func fetchFavorites(userId: UUID) async throws -> [FavoriteDTO] {
        try await client.from("favorites").select().eq("user_id", value: userId).execute().value
    }
    func fetchInscriptions(userId: UUID) async throws -> [InscriptionDTO] {
        try await client.from("inscriptions").select().eq("user_id", value: userId).execute().value
    }
    func fetchCheckins(userId: UUID) async throws -> [CheckinDTO] {
        try await client.from("checkins").select().eq("user_id", value: userId).execute().value
    }
}
