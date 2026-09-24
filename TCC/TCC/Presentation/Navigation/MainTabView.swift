import SwiftUI

struct MainTabView: View {
    @StateObject private var eventListViewModel = EventListVM(
        eventRepository: SupabaseEventRepository(),
        categoryRepository: SupabaseCategoryRepository()
    )
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var discoverRouter = Router()
    @StateObject private var mapRouter = Router()

    var body: some View {
        TabView {
            NavigationStack(path: $discoverRouter.path) {
                EventListView(viewModel: eventListViewModel, router: discoverRouter)
                    .navigationDestination(for: AppRoute.self, destination: destinationView)
            }
            .tabItem { Label("Descobrir", systemImage: "safari") }

            NavigationStack(path: $mapRouter.path) {
                MapView(viewModel: eventListViewModel, router: mapRouter)
                    .navigationDestination(for: AppRoute.self, destination: destinationView)
            }
            .tabItem { Label("Mapa", systemImage: "map") }

            Text("Calendário")
                .tabItem { Label("Calendário", systemImage: "calendar") }

            Text("Histórico")
                .tabItem { Label("Histórico", systemImage: "clock.arrow.circlepath") }

            Text("Perfil")
                .tabItem { Label("Perfil", systemImage: "person") }
        }
        .environmentObject(favoritesStore)
        .tint(AppColor.primaria)
        .task { await eventListViewModel.load() }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .eventDetail(let event):
            EventDetailView(viewModel: eventListViewModel.detailViewModel(for: event))
        }
    }
}
