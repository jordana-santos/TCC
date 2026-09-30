
import Foundation

protocol ProfileRepository {
    func fetchCurrentProfile() async throws -> Profile
    func update(_ profile: Profile) async throws
    func updateLocation(city: String, state: String, latitude: Double, longitude: Double) async throws
}
