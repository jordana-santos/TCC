
import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: EventListVM
    let router: Router

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedEvent: Event?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(viewModel.filteredEvents) { event in
                    Annotation(event.title, coordinate: event.coordinate) {
                        pin(for: event)
                            .onTapGesture { selectedEvent = event }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onAppear { centerOnEvents() }

            VStack(spacing: 12) {
                searchBar
                Spacer()
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
            TextField("Eventos perto de você", text: $viewModel.searchText)
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.textoPrimario)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        case "show": return "music.note"
        case "teatro": return "theatermasks.fill"
        case "exposição", "exposicao": return "paintpalette.fill"
        case "feira": return "tent.fill"
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

    private func centerOnEvents() {
        guard let first = viewModel.filteredEvents.first else { return }
        cameraPosition = .region(
            MKCoordinateRegion(
                center: first.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        )
    }
}

private extension Event {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}
