import Foundation
import Combine

@MainActor
final class EventDetailVM: ObservableObject {
    @Published private(set) var event: Event
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: EventRepository
    private let onUpdate: ((Event) -> Void)?

    init(event: Event, repository: EventRepository, onUpdate: ((Event) -> Void)? = nil) {
        self.event = event
        self.repository = repository
        self.onUpdate = onUpdate
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            event = try await repository.fetchEvent(id: event.id)
            onUpdate?(event)
        } catch {
            errorMessage = "Não foi possível atualizar o evento."
        }
    }
}
