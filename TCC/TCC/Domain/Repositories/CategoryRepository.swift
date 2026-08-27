//é um contrato (protocolo)
// diz >o que< dá pra fazer com os dados (buscar, criar, editar...) sem dizer >como<

import Foundation

protocol CategoryRepository {
    func fetchCategories() async throws -> [Category]
}
