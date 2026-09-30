
import SwiftUI


struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = AuthVM()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Text("Entrar")
                    .font(AppFont.tituloDetalhe)
                    .foregroundStyle(AppColor.textoPrimario)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("E-mail", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .authFieldStyle()
                SecureField("Senha", text: $viewModel.password)
                    .textContentType(.password)
                    .authFieldStyle()

                if let message = viewModel.errorMessage {
                    Text(message).font(AppFont.legenda).foregroundStyle(AppColor.erro)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        if await viewModel.signIn(session: session) { session.didAuthenticate() }
                        }
                } label: {
                    Group {
                        if viewModel.isLoading { ProgressView() } else { Text("Entrar") }
                    }
                    .font(AppFont.rotulo).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                }
                .background(AppColor.primaria.opacity(viewModel.canSignIn ? 1 : 0.4), in: Capsule())
                .disabled(!viewModel.canSignIn || viewModel.isLoading)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Agora não") { dismiss() }
                            .foregroundStyle(AppColor.textoSecondario)
                    }
                }

                NavigationLink("Criar conta") { SignUpView() }
                    .font(AppFont.legenda).foregroundStyle(AppColor.secundaria)
                Spacer()
            }
            .padding(24)
            .background(AppColor.fundo.ignoresSafeArea())
        }
    }
}

extension View {
    func authFieldStyle() -> some View {
        self.padding(14)
            .background(AppColor.cards, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(AppColor.textoPrimario)
    }
}
