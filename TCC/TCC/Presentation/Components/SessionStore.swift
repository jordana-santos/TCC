import Foundation
import Combine
import CoreLocation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var currentProfile: Profile?
    @Published var isPresentingLogin = false

    private let authRepository: AuthRepository
    private let profileRepository: ProfileRepository
    private var pendingAction: (() -> Void)?

    var isAuthenticated: Bool { currentProfile != nil }

    init(authRepository: AuthRepository? = nil, profileRepository: ProfileRepository? = nil) {
        self.authRepository = authRepository ?? SupabaseAuthRepository()
        self.profileRepository = profileRepository ?? SupabaseProfileRepository()
    }

    func loadSession() async {
        guard await authRepository.currentUserId() != nil else {
            currentProfile = nil
            return
        }
        currentProfile = try? await profileRepository.fetchCurrentProfile()
    }

    func signUp(email: String, password: String, displayName: String, city: String, state: String) async throws {
        let coordinate = try await CityGeocoder.coordinate(city: city, state: state)
        try await authRepository.signUp(email: email, password: password, displayName: displayName)
        _ = try await fetchProfileWithRetry()
        try await profileRepository.updateLocation(city: city, state: state, latitude: coordinate.latitude,longitude: coordinate.longitude)
        currentProfile = try await profileRepository.fetchCurrentProfile()
    }

    func signIn(email: String, password: String) async throws {
        try await authRepository.signIn(email: email, password: password)
        currentProfile = try await profileRepository.fetchCurrentProfile()
    }

    func signOut() async {
        try? await authRepository.signOut()
        currentProfile = nil
    }

    func requireAuth(_ action: @escaping () -> Void) {
        if isAuthenticated {
            action()
        } else {
            pendingAction = action
            isPresentingLogin = true
        }
    }

    func didAuthenticate() {
        isPresentingLogin = false
        let action = pendingAction
        pendingAction = nil
        action?()
    }

    private func fetchProfileWithRetry() async throws -> Profile {
        for _ in 0..<2 {
            if let profile = try? await profileRepository.fetchCurrentProfile() {
                return profile
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        return try await profileRepository.fetchCurrentProfile()
    }
    
    func setProducer(_ isProducer: Bool) async throws {
        let role: AccountType = isProducer ? .producer : .attendee
        try await profileRepository.updateRole(role)
        currentProfile?.role = role
    }
}
