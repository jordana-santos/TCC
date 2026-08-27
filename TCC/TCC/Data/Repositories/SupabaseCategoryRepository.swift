//implementacao real do protocolo do domain
//chama o data source, pega o dto, e converte para entity antes de devolver
//é uma ponte pra domain

import Foundation

final class SupabaseCategoryRepository: CategoryRepository {
    private let dataSource = CategoryDS()
    func fetchCategories() async throws -> [Category] {
        try await dataSource.fetchCategories().map { $0.toEntity() }
    }
}
