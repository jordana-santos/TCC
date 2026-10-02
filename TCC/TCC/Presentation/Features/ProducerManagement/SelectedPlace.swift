
import Foundation
import Combine
import MapKit
import CoreLocation

struct SelectedPlace: Equatable {
    let address: String
    let latitude: Double
    let longitude: Double
}

@MainActor
final class AddressSearchVM: NSObject, ObservableObject {
    @Published var query = "" {
        didSet {
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                suggestions = []
            } else {
                completer.queryFragment = trimmed
            }
        }
    }
    @Published private(set) var suggestions: [MKLocalSearchCompletion] = []
    @Published private(set) var isResolving = false
    @Published var errorMessage: String?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func clear() {
        query = ""
        suggestions = []
        errorMessage = nil
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> SelectedPlace? {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }
        do {
            let response = try await MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start()
            guard let item = response.mapItems.first else {
                errorMessage = "Não foi possível localizar esse endereço. Tente outro."
                return nil
            }
            let coordinate = item.placemark.coordinate
            return SelectedPlace(
                address: Self.displayText(for: completion),
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        } catch {
            print("Erro ao localizar endereço:", error)
            errorMessage = "Não foi possível localizar esse endereço. Tente outro."
            return nil
        }
    }

    private static func displayText(for completion: MKLocalSearchCompletion) -> String {
        let title = completion.title.trimmingCharacters(in: .whitespaces)
        let subtitle = completion.subtitle.trimmingCharacters(in: .whitespaces)
        if subtitle.isEmpty { return title }
        if subtitle.localizedCaseInsensitiveContains(title) { return subtitle }
        return "\(title), \(subtitle)"
    }
}

extension AddressSearchVM: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.suggestions = Array(results.prefix(6))
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
        }
    }
}
