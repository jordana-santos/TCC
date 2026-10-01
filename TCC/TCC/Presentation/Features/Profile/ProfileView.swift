
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore

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
