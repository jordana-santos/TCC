import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionStore()

    var body: some View {
        MainTabView()
            .environmentObject(session)
            .sheet(isPresented: $session.isPresentingLogin) {
                LoginView()
                    .environmentObject(session)
            }
            .preferredColorScheme(.dark)
            .task { await session.loadSession() }
    }
}
