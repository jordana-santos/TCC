//so swift puro
//so tem as structs e a definicao dos tipos dos campos (evento, usuario, categoria...)
//so guarda dados, nao tem nenhuma logica

import SwiftUI

struct Category: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String?
}
