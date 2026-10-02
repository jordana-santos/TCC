import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var pendingProducer: Bool?   // valor mostrado enquanto grava no banco
    @State private var roleError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                if let profile = session.currentProfile {
                    Text(profile.displayName)
                        .font(AppFont.tituloDetalhe)
                        .foregroundStyle(AppColor.textoPrimario)
                    if let city = profile.city, let state = profile.state {
                        Text("\(city), \(state)")
                            .font(AppFont.metadado)
                            .foregroundStyle(AppColor.textoSecondario)
                    }
                    producerToggle(for: profile)
                    actionButton("Sair", filled: false) {
                        Task { await session.signOut() }
                    }
                } else {
                    Text("Você não está logado")
                        .font(AppFont.corpo)
                        .foregroundStyle(AppColor.textoSecondario)
                    actionButton("Entrar", filled: true) {
                        session.isPresentingLogin = true
                    }
                }
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(AppColor.fundo.ignoresSafeArea())
        }
    }

    private func producerToggle(for profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { pendingProducer ?? (profile.role == .producer) },
                set: { updateRole($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sou produtor de eventos")
                        .font(AppFont.corpo)
                        .foregroundStyle(AppColor.textoPrimario)
                }
            }
            .tint(AppColor.primaria)
            .disabled(pendingProducer != nil)

            if let roleError {
                Text(roleError)
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.erro)
            }
        }
        .padding(14)
        .background(AppColor.cards, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func updateRole(_ isProducer: Bool) {
        roleError = nil
        pendingProducer = isProducer
        Task { @MainActor in
            do {
                try await session.setProducer(isProducer)
            } catch {
                print("Erro ao atualizar role:", error)
                roleError = "Não foi possível alterar o tipo de conta. Tente de novo."
            }
            pendingProducer = nil
        }
    }

    private func actionButton(_ title: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.rotulo)
                .foregroundStyle(filled ? .white : AppColor.textoPrimario)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .background(filled ? AppColor.primaria : AppColor.clicavel, in: Capsule())
    }
}
