import Supabase
import SwiftUI

struct ContentView: View {
    @State private var categories: [Category] = []
    @State private var log: [String] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                Section("Categorias (\(categories.count))") {
                    if categories.isEmpty {
                        Text("Nenhuma categoria carregada ainda")
                            .font(AppFont.corpo)
                    }
                    ForEach(categories) { category in
                        Text(category.name)
                            .font(AppFont.corpo)
                    }
                }

                if !log.isEmpty {
                    Section("Teste") {
                        ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(AppFont.legenda)
                        }
                    }
                }
            }
            .textSelection(.enabled)
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await runFullTest() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Label("Rodar teste", systemImage: "play.fill")
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .task { await loadCategories() }
        }
    }

    

    private func loadCategories() async {
        log.append("… buscando categorias")
        do {
            let result = try await SupabaseCategoryRepository().fetchCategories()
            categories = result
            log.append("\(result.count) categoria(s): \(result.map(\.name).joined(separator: ", "))")

        } catch {
            log.append("Categorias: \(error)")
        }
    }
    
    private func nextTestRunNumber() -> Int {
        let key = "testRunCounter"
        let next = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(next, forKey: key)
        return next
    }

    private func runFullTest() async {
        isLoading = true
        log.removeAll()
        defer { isLoading = false }

        do {
            let number = nextTestRunNumber()

            log.append("… cadastrando produtora")
            let email = "produtora\(number)@example.com"
            let signUpResponse = try await SupabaseManager.shared.auth.signUp(
                email: email,
                password: "SenhaForte123!",
                data: ["display_name": .string("Produtora Teste"), "role": .string("producer")]
            )
            let producerId = signUpResponse.user.id
            log.append("Cadastrada: \(email)")
            log.append("id: \(producerId)")

            if (try? await SupabaseManager.shared.auth.session) != nil {
                log.append("Sessão ativa (access token presente)")
            } else {
                log.append("SEM sessão ativa. Provavelmente confirmação de e-mail está ligada")
            }

            guard let musica = categories.first(where: { $0.name == "Música" }) else {
                log.append("Categoria 'Música' não está entre as \(categories.count) carregadas")
                return
            }
            log.append("… criando evento na categoria \(musica.name)")

            let newEvent = Event(
                id: UUID(), title: "Show teste \(number)",
                description: "Evento de teste criado pelo app",
                startsAt: .now.addingTimeInterval(86400),
                endsAt: .now.addingTimeInterval(86400 + 7200),
                price: 20, capacityMax: 50, attendeeCount: 0,
                externalLink: nil, imageURL: nil, status: .published,
                producerId: producerId,
                location: Location(address: "Rua Harmonia, 100", latitude: -23.556, longitude: -46.689),
                categories: [musica]
            )
            try await SupabaseEventRepository().create(newEvent)
            log.append("Evento criado: \(newEvent.title)")

            log.append("… buscando eventos filtrando por \(musica.name)")
            let events = try await SupabaseEventRepository().fetchEvents(filter: EventFilter(categoryId: musica.id))
            log.append("\(events.count) evento(s): \(events.map(\.title).joined(separator: ", "))")
        } catch {
            log.append("Erro: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
