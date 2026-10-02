import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: EventListVM
    let router: Router

    @EnvironmentObject private var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedEvent: Event?
    @State private var hasInitialPosition = false

    /// Onde você está de verdade. Sem localização, usa a cidade de referência.
    private var homeCoordinate: CLLocationCoordinate2D? {
        locationManager.userLocation ?? viewModel.referenceCoordinate
    }

    /// Eventos dentro da região que aparece na tela, sem limite de raio.
    private var visibleEvents: [Event] {
        let events = viewModel.baseFilteredEvents
        guard let region = visibleRegion else { return events }
        let minLat = region.center.latitude - region.span.latitudeDelta / 2
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2
        let minLon = region.center.longitude - region.span.longitudeDelta / 2
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2
        return events.filter {
            $0.location.latitude >= minLat && $0.location.latitude <= maxLat
                && $0.location.longitude >= minLon && $0.location.longitude <= maxLon
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(visibleEvents) { event in
                    Annotation(event.title, coordinate: event.coordinate) {
                        pin(for: event)
                            .onTapGesture { selectedEvent = event }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
            }
            .onAppear { positionInitiallyIfNeeded() }
            .onChange(of: homeCoordinate?.latitude) { _, _ in positionInitiallyIfNeeded() }
            .onChange(of: viewModel.events.count) { _, _ in positionInitiallyIfNeeded() }
            .onChange(of: viewModel.searchText) { _, text in
                if !text.isEmpty { frameResults() }
            }
            .onChange(of: viewModel.selectedCategoryIds) { _, _ in frameResultsIfFiltering() }
            .onChange(of: viewModel.selectedDate) { _, _ in frameResultsIfFiltering() }
            .onChange(of: viewModel.freeOnly) { _, _ in frameResultsIfFiltering() }
            .onChange(of: viewModel.maxPrice) { _, _ in frameResultsIfFiltering() }

            VStack(spacing: 12) {
                searchBar
                Spacer()
                if homeCoordinate != nil {
                    HStack {
                        Spacer()
                        recenterButton
                    }
                }
                if let event = selectedEvent {
                    previewCard(for: event)
                }
            }
            .padding(16)
        }
        .background(AppColor.fundo)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColor.textMuted)
            TextField("Buscar eventos", text: $viewModel.searchText)
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.textoPrimario)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var recenterButton: some View {
        Button(action: recenter) {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColor.primaria)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private func pin(for event: Event) -> some View {
        let color = event.categories.first.map { CategoryTagView.style(for: $0).text } ?? AppColor.textMuted
        return Image(systemName: pinIcon(for: event))
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppColor.fundo)
            .padding(10)
            .background(color, in: Circle())
            .overlay(Circle().strokeBorder(AppColor.fundo, lineWidth: 2))
    }

    private func pinIcon(for event: Event) -> String {
        switch event.categories.first?.name.lowercased() {
        case "música", "musica": return "music.note"
        case "teatro": return "theatermasks.fill"
        case "arte e exposições", "arte e exposicoes": return "paintpalette.fill"
        case "gastronomia": return "fork.knife"
        default: return "mappin"
        }
    }

    private func previewCard(for event: Event) -> some View {
        Button {
            router.push(.eventDetail(event))
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.clicavel)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    if let category = event.categories.first {
                        CategoryTagView(category: category)
                    }
                    Text(event.title)
                        .font(AppFont.tituloCard)
                        .foregroundStyle(AppColor.textoPrimario)
                        .lineLimit(1)
                    Text(event.startsAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "pt_BR"))))
                        .font(AppFont.metadado)
                        .foregroundStyle(AppColor.textoSecondario)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColor.textMuted)
            }
            .padding(12)
            .background(AppColor.cards, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func positionInitiallyIfNeeded() {
        guard !hasInitialPosition else { return }
        if let home = homeCoordinate {
            cameraPosition = .region(region(around: home, radiusKm: 5))
            hasInitialPosition = true
        } else if let region = region(for: viewModel.baseFilteredEvents) {
            cameraPosition = .region(region)
        }
    }

    private func frameResultsIfFiltering() {
        guard viewModel.hasActiveFilters else { return }
        frameResults()
    }

    private func frameResults() {
        let events = viewModel.baseFilteredEvents
        selectedEvent = events.count == 1 ? events.first : nil
        if let region = region(for: events) {
            withAnimation {
                cameraPosition = .region(region)
            }
        }
    }

    private func recenter() {
        guard let home = homeCoordinate else { return }
        viewModel.searchText = ""
        selectedEvent = nil
        withAnimation {
            cameraPosition = .region(region(around: home, radiusKm: 5))
        }
    }

    private func region(around coordinate: CLLocationCoordinate2D, radiusKm: Double) -> MKCoordinateRegion {
        let latDelta = (radiusKm * 2) / 111.0
        let lonDelta = (radiusKm * 2) / (111.0 * max(cos(coordinate.latitude * .pi / 180), 0.1))
        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    private func region(for events: [Event]) -> MKCoordinateRegion? {
        guard !events.isEmpty else { return nil }
        let coordinates = events.map(\.coordinate)
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.05, (maxLat - minLat) * 1.6),
            longitudeDelta: max(0.05, (maxLon - minLon) * 1.6)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

private extension Event {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}
