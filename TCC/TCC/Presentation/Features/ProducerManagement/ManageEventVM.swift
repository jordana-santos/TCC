
import Foundation
import Combine

enum ManageEventSegment: CaseIterable, Identifiable {
    case upcoming
    case past

    var id: Self { self }

    var title: String {
        switch self {
        case .upcoming: return "Próximos"
        case .past: return "Encerrados"
        }
    }
}

@MainActor
final class ManageEventVM: ObservableObject {
    @Published private(set) var events: [Event] = []
    @Published var segment: ManageEventSegment = .upcoming
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published var errorMessage: String?

    private let repository: EventRepository

    init(repository: EventRepository) {
        self.repository = repository
    }

    var upcomingEvents: [Event] {
        let now = Date()
        return events
            .filter { $0.endsAt >= now }
            .sorted { $0.startsAt < $1.startsAt }
    }

    var pastEvents: [Event] {
        let now = Date()
        return events
            .filter { $0.endsAt < now }
            .sorted { $0.startsAt > $1.startsAt }
    }

    var visibleEvents: [Event] {
        segment == .upcoming ? upcomingEvents : pastEvents
    }

    func load(producerId: UUID) async {
        if !hasLoaded { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }
        do {
            events = try await repository.fetchProducerEvents(producerId: producerId)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            print("Erro ao carregar eventos do produtor:", error)
            errorMessage = "Não foi possível carregar seus eventos."
        }
    }

    func reset() {
        events = []
        hasLoaded = false
        errorMessage = nil
    }
}
