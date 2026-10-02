
import Foundation
import Auth

final class SupabaseAuthRepository: AuthRepository {
    private let dataSource = AuthDS()

    func currentUserId() async -> UUID? {
        await dataSource.currentSession()?.user.id
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let session = try await dataSource.signUp(email: email, password: password, displayName: displayName)
    }

    func signIn(email: String, password: String) async throws {
        _ = try await dataSource.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await dataSource.signOut()
    }
}
