import Foundation
import Combine

@MainActor
final class EventDetailVM: ObservableObject {
    @Published private(set) var event: Event
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Engajamento (favoritar, marcar presença, check-in)
    // Ainda não integrado: depende das entidades Favorite/Inscription/Checkin e do
    // repositório da feature Event Engagement, que não foram compartilhados comigo.
    // Por enquanto é só estado local de UI, não persiste em lugar nenhum.
    @Published var isFavorited = false
    @Published var isGoing = false
    @Published var hasCheckedIn = false

    private let repository: EventRepository

    init(event: Event, repository: EventRepository) {
        self.event = event
        self.repository = repository
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            event = try await repository.fetchEvent(id: event.id)
        } catch {
            errorMessage = "Não foi possível atualizar o evento."
        }
    }

    func toggleFavorite() { isFavorited.toggle() }
    func markGoing() { isGoing = true }
    func checkIn() { hasCheckedIn = true }
}
