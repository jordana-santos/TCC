
import Foundation
import Supabase

final class ProfileDS {
    private let client = SupabaseManager.shared

    func fetchProfile(id: UUID) async throws -> ProfileDTO {
        try await client.from("profiles").select().eq("id", value: id).single().execute().value
    }

    func updateProfile(id: UUID, displayName: String, photoURL: String?) async throws {
        struct Payload: Encodable {
            let displayName: String; let photoURL: String?
            enum CodingKeys: String, CodingKey { case displayName = "display_name", photoURL = "photo_url" }
        }
        try await client.from("profiles")
            .update(Payload(displayName: displayName, photoURL: photoURL))
            .eq("id", value: id).execute()
    }
}
