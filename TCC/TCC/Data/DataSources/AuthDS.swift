
import Foundation
import Supabase
import Auth 

final class AuthDS {
    private let client = SupabaseManager.shared

    func currentSession() async -> Session? {
        try? await client.auth.session
    }

    func signUp(email: String, password: String, displayName: String) async throws -> Session? {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": .string(displayName)]
        )
        return response.session
    }

    func signIn(email: String, password: String) async throws -> Session {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }
}
