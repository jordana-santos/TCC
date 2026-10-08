import SwiftUI
import CoreLocation

struct MainTabView: View {
    private enum AppTab: Hashable {
        case discover, map, calendar, history, producerEvents, profile
    }

    @StateObject private var eventListViewModel = EventListVM(
        eventRepository: SupabaseEventRepository(),
        categoryRepository: SupabaseCategoryRepository()
    )
    @StateObject private var engagementStore = EngagementStore()
    @StateObject private var discoverRouter = Router()
    @StateObject private var mapRouter = Router()
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var locationManager: LocationManager
    @State private var selectedTab: AppTab = .discover
    @StateObject private var producerRouter = Router()
    @StateObject private var manageEventsViewModel = ManageEventVM(repository: SupabaseEventRepository())
    @StateObject private var calendarRouter = Router()
    private var isProducer: Bool {
        session.currentProfile?.role == .producer
    }
    

    private struct ReferenceInputs: Equatable {
        var latitude: Double?
        var longitude: Double?
        var isResolving: Bool
        var profileId: UUID?
    }

    private var referenceInputs: ReferenceInputs {
        ReferenceInputs(
            latitude: locationManager.userLocation?.latitude,
            longitude: locationManager.userLocation?.longitude,
            isResolving: locationManager.isResolving,
            profileId: session.currentProfile?.id
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            if isProducer {
                producerTabs
            } else {
                attendeeTabs
            }
        }
        .environmentObject(engagementStore)
        .tint(AppColor.primaria)
        .task { await eventListViewModel.load() }
        .task(id: session.currentProfile?.id) {
            if session.isAuthenticated {
                await engagementStore.loadHistory()
            } else {
                engagementStore.clear()
            }
        }
        .task { locationManager.requestLocation() }
        .onAppear { refreshReference() }
        .onChange(of: referenceInputs) { _, _ in refreshReference() }
        .onChange(of: isProducer) { _, producer in fixSelectedTab(isProducer: producer) }
        .onChange(of: selectedTab) { _, tab in
            if tab == .discover || tab == .map {
                Task { await eventListViewModel.refresh() }
            }
            if tab == .calendar {
                if isProducer, let producerId = session.currentProfile?.id {
                    Task { await manageEventsViewModel.load(producerId: producerId) }
                } else {
                    Task { await eventListViewModel.refresh() }
                }
            }
        }
    }

    @ViewBuilder
    private var attendeeTabs: some View {
        NavigationStack(path: $discoverRouter.path) {
            EventListView(viewModel: eventListViewModel, router: discoverRouter)
                .navigationDestination(for: AppRoute.self, destination: destinationView)
        }
        .tabItem { Label("Descobrir", systemImage: "safari") }
        .tag(AppTab.discover)

        NavigationStack(path: $mapRouter.path) {
            MapView(viewModel: eventListViewModel, router: mapRouter)
                .navigationDestination(for: AppRoute.self, destination: destinationView)
        }
        .tabItem { Label("Mapa", systemImage: "map") }
        .tag(AppTab.map)

        calendarTab

        Text("Histórico")
            .tabItem { Label("Histórico", systemImage: "clock.arrow.circlepath") }
            .tag(AppTab.history)

        ProfileView()
            .tabItem { Label("Perfil", systemImage: "person") }
            .tag(AppTab.profile)
    }

    //lado do produtor
    @ViewBuilder
    private var producerTabs: some View {
        NavigationStack(path: $producerRouter.path) {
            ManageEventListView(viewModel: manageEventsViewModel, router: producerRouter)
                .navigationDestination(for: AppRoute.self, destination: destinationView)
        }
        .tabItem { Label("Eventos", systemImage: "ticket") }
        .tag(AppTab.producerEvents)

        calendarTab

        ProfileView()
            .tabItem { Label("Perfil", systemImage: "person") }
            .tag(AppTab.profile)
    }

    private func fixSelectedTab(isProducer: Bool) {
        if isProducer {
            if [.discover, .map, .history].contains(selectedTab) {
                selectedTab = .producerEvents
            }
        } else if selectedTab == .producerEvents {
            selectedTab = .discover
        }
    }

    private func refreshReference() {
        eventListViewModel.updateReference(
            deviceLocation: locationManager.userLocation,
            isLocationPending: locationManager.isResolving,
            profile: session.currentProfile
        )
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .eventDetail(let event):
            EventDetailView(viewModel: eventListViewModel.detailViewModel(for: event))
        }
    }
    
    @ViewBuilder
    private var calendarTab: some View {
        NavigationStack(path: $calendarRouter.path) {
            CalendarView(
                mode: isProducer ? .producer : .attendee,
                events: isProducer
                    ? manageEventsViewModel.events
                    : eventListViewModel.events.filter { engagementStore.isGoing($0.id) },
                router: calendarRouter
            )
            .navigationDestination(for: AppRoute.self, destination: destinationView)
        }
        .tabItem { Label("Calendário", systemImage: "calendar") }
        .tag(AppTab.calendar)
    }
}
