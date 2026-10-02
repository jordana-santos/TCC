import Foundation
import CoreLocation

struct CityPlace: Codable, Equatable {
    var city: String
    var state: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var label: String { "\(city), \(state)" }
}

enum SavedCityStore {
    private static let key = "savedVisitorCity"

    static func load() -> CityPlace? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CityPlace.self, from: data)
    }

    static func save(_ place: CityPlace) {
        guard let data = try? JSONEncoder().encode(place) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
