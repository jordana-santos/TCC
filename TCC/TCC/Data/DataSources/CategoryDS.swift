//quem conversa com o supabase
//faz a chamada (.from().select().execute()) e devolve DTOs

import Foundation
import Supabase

final class CategoryDS {
    private let client = SupabaseManager.shared

    func fetchCategories() async throws -> [CategoryDTO] {
        try await client.from("categories").select().order("name").execute().value
    }
}
