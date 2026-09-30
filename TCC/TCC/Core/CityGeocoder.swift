
import Foundation
import CoreLocation

enum CityGeocoder {
    struct CityNotFound: LocalizedError {
        var errorDescription: String? { "Não encontramos essa cidade. Confira o nome e o estado." }
    }

    static func coordinate(city: String, state: String) async throws -> CLLocationCoordinate2D {
        let placemarks = try await CLGeocoder().geocodeAddressString("\(city), \(state), Brasil")
        guard let coordinate = placemarks.first?.location?.coordinate else { throw CityNotFound() }
        return coordinate
    }
}
