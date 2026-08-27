
import Foundation

protocol EventRepository {
    func fetchEvents() async throws -> [Event]
    func fetchEvent(id: UUID) async throws -> Event
    func create(_ event: Event) async throws
    func update(_ event: Event) async throws
    func delete(id: UUID) async throws
}
