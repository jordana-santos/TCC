import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionStore()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        MainTabView()
            .environmentObject(session)
            .environmentObject(locationManager)
            .sheet(isPresented: $session.isPresentingLogin) {
                LoginView()
                    .environmentObject(session)
            }
            .preferredColorScheme(.dark)
            .task { await session.loadSession() }
    }
}
