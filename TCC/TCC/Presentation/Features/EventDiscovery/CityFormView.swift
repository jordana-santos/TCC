import SwiftUI

struct CityFormView: View {
    let buttonTitle: String
    let onSubmit: (String, String) async throws -> Void

    @State private var city = ""
    @State private var state: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    @MainActor
    init(buttonTitle: String,
         initialState: String = "AC",
         onSubmit: @escaping (String, String) async throws -> Void) {
        self.buttonTitle = buttonTitle
        self.onSubmit = onSubmit
        _state = State(initialValue: AuthVM.states.contains(initialState) ? initialState : "AC")
    }

    private var canSubmit: Bool {
        !city.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TextField("Cidade", text: $city)
                    .textContentType(.addressCity).authFieldStyle()
                Picker("UF", selection: $state) {
                    ForEach(AuthVM.states, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(AppColor.secundaria)
                .padding(.vertical, 6).padding(.horizontal, 8)
                .background(AppColor.cards, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.erro)
                    .multilineTextAlignment(.center)
            }

            Button(action: submit) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(buttonTitle).font(AppFont.rotulo)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .background(AppColor.primaria, in: Capsule())
            .opacity(canSubmit ? 1 : 0.5)
            .disabled(!canSubmit)
        }
    }

    private func submit() {
        errorMessage = nil
        isLoading = true
        Task { @MainActor in
            do {
                try await onSubmit(city.trimmingCharacters(in: .whitespaces), state)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
