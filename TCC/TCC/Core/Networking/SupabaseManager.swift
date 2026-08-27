
import Foundation
import Supabase

enum SupabaseManager {
    static let shared = SupabaseClient(
        supabaseURL: URL(string: "https://ndaeuwldrgvlpamjltrp.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kYWV1d2xkcmd2bHBhbWpsdHJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0ODM3NTMsImV4cCI6MjEwMzA1OTc1M30.dUZsQNWOAalgCJuDGQupeKPnhLmM52Q2uDa-iartVgE"
    )
}
