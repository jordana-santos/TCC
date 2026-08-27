import Foundation
import Supabase

final class SupabaseProfileRepository: ProfileRepository {
    private let dataSource = ProfileDS()
    private let client = SupabaseManager.shared

    func fetchCurrentProfile() async throws -> Profile {
        let userId = try await client.auth.session.user.id
        return try await dataSource.fetchProfile(id: userId).toEntity()
    }
    func update(_ profile: Profile) async throws {
        try await dataSource.updateProfile(id: profile.id, displayName: profile.displayName, photoURL: profile.photoURL)
    }
}
