
import Foundation

protocol AuthRepository {
    func currentUserId() async -> UUID?
    func signUp(email: String, password: String, displayName: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut() async throws
}
