
import Foundation

protocol ProfileRepository {
    func fetchCurrentProfile() async throws -> Profile
    func update(_ profile: Profile) async throws
}
