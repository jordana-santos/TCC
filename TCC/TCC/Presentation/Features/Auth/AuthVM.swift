
import Foundation
import Combine

@MainActor
final class AuthVM: ObservableObject {
    static let states = ["AC","AL","AP","AM","BA","CE","DF","ES","GO","MA","MT","MS","MG",
                         "PA","PB","PR","PE","PI","RJ","RN","RS","RO","RR","SC","SP","SE","TO"]

    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var city = ""
    @Published var state = "SP"
    @Published var isLoading = false
    @Published var errorMessage: String?

    var canSignIn: Bool { email.contains("@") && password.count >= 6 }
    var canSignUp: Bool {
        canSignIn && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @discardableResult
    func signIn(session: SessionStore) async -> Bool {
        await run { try await session.signIn(email: self.email.trimmingCharacters(in: .whitespaces),
                                             password: self.password) }
    }

    @discardableResult
    func signUp(session: SessionStore) async -> Bool {
        await run {
            try await session.signUp(email: self.email.trimmingCharacters(in: .whitespaces),
                                     password: self.password,
                                     displayName: self.displayName.trimmingCharacters(in: .whitespaces),
                                     city: self.city.trimmingCharacters(in: .whitespaces),
                                     state: self.state)
        }
    }

    private func run(_ action: @escaping () async throws -> Void) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await action()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
