import Foundation

enum AppRoute: Hashable {
    case eventDetail(Event)

    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.eventDetail(l), .eventDetail(r)):
            return l.id == r.id
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .eventDetail(let event):
            hasher.combine(event.id)
        }
    }
}
