
import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = AuthVM()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Criar conta")
                    .font(AppFont.tituloDetalhe)
                    .foregroundStyle(AppColor.textoPrimario)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Nome", text: $viewModel.displayName)
                    .textContentType(.name).authFieldStyle()
                TextField("E-mail", text: $viewModel.email)
                    .textContentType(.emailAddress).keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().authFieldStyle()
                SecureField("Senha (mínimo 6 caracteres)", text: $viewModel.password)
                    .textContentType(.newPassword).authFieldStyle()

                HStack(spacing: 12) {
                    TextField("Cidade", text: $viewModel.city)
                        .textContentType(.addressCity).authFieldStyle()
                    Picker("UF", selection: $viewModel.state) {
                        ForEach(AuthVM.states, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColor.secundaria)
                    .padding(.vertical, 6).padding(.horizontal, 8)
                    .background(AppColor.cards, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Text("Usamos a cidade para mostrar eventos perto de você caso a localização esteja desativada.")
                    .font(AppFont.legenda).foregroundStyle(AppColor.textoSecondario)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let message = viewModel.errorMessage {
                    Text(message).font(AppFont.legenda).foregroundStyle(AppColor.erro)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { if await viewModel.signUp(session: session) { session.didAuthenticate() }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading { ProgressView() } else { Text("Criar conta") }
                    }
                    .font(AppFont.rotulo).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                }
                .background(AppColor.primaria.opacity(viewModel.canSignUp ? 1 : 0.4), in: Capsule())
                .disabled(!viewModel.canSignUp || viewModel.isLoading)
            }
            .padding(24)
        }
        .background(AppColor.fundo.ignoresSafeArea())
    }
}
