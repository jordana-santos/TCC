
import Foundation

struct CategoryDTO: Codable {
    let id: UUID
    let name: String
    let description: String?

    func toEntity() -> Category {
        Category(id: id, name: name, description: description)
    }
}
