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
    
    func updateLocation(city: String, state: String, latitude: Double, longitude: Double) async throws {
        let userId = try await SupabaseManager.shared.auth.session.user.id
        try await ProfileDS().updateLocation(id: userId, city: city, state: state, latitude: latitude, longitude: longitude)
    }
    
    func updateRole(_ role: AccountType) async throws {
        let userId = try await client.auth.session.user.id
        try await dataSource.updateRole(id: userId, role: role.rawValue)
    }
}
