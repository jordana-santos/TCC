import SwiftUI
import MapKit

struct EventFormView: View {
    @StateObject private var viewModel: EventFormVM
    @StateObject private var addressSearch = AddressSearchVM()
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool
    @State private var showDeleteAlert = false
    @State private var showCancelAlert = false

    let onSaved: () -> Void
    let onDeleted: () -> Void

    @MainActor
    init(mode: EventFormMode = .create,
         onSaved: @escaping () -> Void,
         onDeleted: @escaping () -> Void = {}) {
        self.onSaved = onSaved
        self.onDeleted = onDeleted
        _viewModel = StateObject(wrappedValue: EventFormVM(
            mode: mode,
            eventRepository: SupabaseEventRepository(),
            categoryRepository: SupabaseCategoryRepository()
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titleSection
                    descriptionSection
                    datesSection
                    locationSection
                    capacitySection
                    priceSection
                    categoriesSection
                    dangerSection

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(AppFont.legenda)
                            .foregroundStyle(AppColor.erro)
                    }
                }
                .padding(20)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColor.fundo.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { actionBar }
            .navigationTitle(viewModel.screenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(viewModel.isEditing ? "Fechar" : "Cancelar") { dismiss() }
                        .foregroundStyle(AppColor.textoSecondario)
                }
            }
            .task { await viewModel.loadCategories() }
            .alert("Excluir evento?", isPresented: $showDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Excluir", role: .destructive) { delete() }
            } message: {
                Text("Esta ação não pode ser desfeita. \"\(viewModel.originalTitle)\" será removido.")
            }
            .alert("Cancelar evento?", isPresented: $showCancelAlert) {
                Button("Voltar", role: .cancel) { }
                Button("Cancelar evento", role: .destructive) { cancelEvent() }
            } message: {
                Text(viewModel.cancelAlertMessage)
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isSaving)
    }

    private func save(as status: EventStatus) {
        guard let producerId = session.currentProfile?.id else { return }
        Task {
            if await viewModel.save(as: status, producerId: producerId) {
                onSaved()
                dismiss()
            }
        }
    }

    private func cancelEvent() {
        Task {
            if await viewModel.cancelEvent() {
                onSaved()
                dismiss()
            }
        }
    }

    private func delete() {
        Task {
            if await viewModel.deleteEvent() {
                onDeleted()
                dismiss()
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            if viewModel.isDraftFlow {
                Button { save(as: .draft) } label: {
                    barLabel("Salvar rascunho", foreground: AppColor.textoPrimario)
                }
                .background(AppColor.clicavel, in: Capsule())
                .opacity(viewModel.canSave ? 1 : 0.5)
                .disabled(!viewModel.canSave)

                Button { save(as: .published) } label: {
                    barLabel("Publicar", foreground: .white)
                }
                .background(AppColor.primaria, in: Capsule())
                .opacity(viewModel.canSave ? 1 : 0.5)
                .disabled(!viewModel.canSave)
            } else {
                Button { save(as: .published) } label: {
                    barLabel("Salvar alterações", foreground: .white)
                }
                .background(AppColor.primaria, in: Capsule())
                .opacity(viewModel.canSave ? 1 : 0.5)
                .disabled(!viewModel.canSave)
            }
        }
        .padding(16)
        .background(AppColor.fundo)
    }

    private func barLabel(_ text: String, foreground: Color) -> some View {
        Group {
            if viewModel.isSaving {
                ProgressView()
            } else {
                Text(text)
            }
        }
        .font(AppFont.rotulo)
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
    }
    
    private func label(_ text: String) -> some View {
        Text(text)
            .font(AppFont.subtitulo)
            .foregroundStyle(AppColor.textoPrimario)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Título")
            TextField("Título", text: $viewModel.title,
                      prompt: Text("Nome do evento").foregroundStyle(AppColor.placeholder))
                .focused($titleFocused)
                .eventFieldStyle(hasError: viewModel.showTitleError)
            if viewModel.showTitleError {
                Text("Dê um nome ao evento")
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.erro)
            }
        }
        .onChange(of: titleFocused) { _, focused in
            if !focused { viewModel.titleTouched = true }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Descrição")
            TextField("Descrição", text: $viewModel.descriptionText,
                      prompt: Text("Conte mais sobre o evento").foregroundStyle(AppColor.placeholder),
                      axis: .vertical)
                .lineLimit(3...6)
                .eventFieldStyle()
        }
    }

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Data e hora")
            VStack(spacing: 12) {
                DatePicker("Início", selection: $viewModel.startsAt,
                           displayedComponents: [.date, .hourAndMinute])
                Divider().overlay(Color.white.opacity(0.08))
                DatePicker("Fim", selection: $viewModel.endsAt,
                           in: viewModel.startsAt...,
                           displayedComponents: [.date, .hourAndMinute])
            }
            .font(AppFont.corpo)
            .foregroundStyle(AppColor.textoPrimario)
            .tint(AppColor.primaria)
            .environment(\.locale, Locale(identifier: "pt_BR"))
            .eventCardStyle()

            if let error = viewModel.dateError {
                Text(error)
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.erro)
            }
        }
    }


    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Localização")
            if let place = viewModel.place {
                selectedPlaceRow(place)
            } else {
                searchField
                if !addressSearch.suggestions.isEmpty {
                    suggestionsList
                }
                if let message = addressSearch.errorMessage {
                    Text(message)
                        .font(AppFont.legenda)
                        .foregroundStyle(AppColor.erro)
                } else {
                    Text("Busque e escolha um endereço da lista.")
                        .font(AppFont.legenda)
                        .foregroundStyle(AppColor.textoSecondario)
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColor.textMuted)
            TextField("Buscar endereço", text: $addressSearch.query,
                      prompt: Text("Buscar endereço").foregroundStyle(AppColor.placeholder))
                .autocorrectionDisabled()
            if addressSearch.isResolving {
                ProgressView().tint(AppColor.primaria)
            }
        }
        .eventFieldStyle()
    }

    private var suggestionsList: some View {
        VStack(spacing: 0) {
            ForEach(addressSearch.suggestions, id: \.self) { suggestion in
                Button { choose(suggestion) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(AppFont.subtitulo)
                            .foregroundStyle(AppColor.textoPrimario)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(AppFont.legenda)
                                .foregroundStyle(AppColor.textoSecondario)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if suggestion != addressSearch.suggestions.last {
                    Divider().overlay(Color.white.opacity(0.08))
                }
            }
        }
        .background(AppColor.cards, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func selectedPlaceRow(_ place: SelectedPlace) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppColor.primaria)
            Text(place.address)
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.textoPrimario)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Trocar") { viewModel.place = nil }
                .font(AppFont.subtitulo)
                .foregroundStyle(AppColor.primaria)
        }
        .eventCardStyle()
    }

    private func choose(_ completion: MKLocalSearchCompletion) {
        Task {
            if let place = await addressSearch.resolve(completion) {
                viewModel.place = place
                addressSearch.clear()
            }
        }
    }

    private var capacitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Capacidade máx.")
            VStack(spacing: 12) {
                Toggle("Sem limite de vagas", isOn: $viewModel.isUnlimitedCapacity)
                    .tint(AppColor.primaria)
                if !viewModel.isUnlimitedCapacity {
                    Stepper(value: $viewModel.capacity, in: viewModel.minCapacity...100_000, step: 10) {
                        Text("\(viewModel.capacity) vagas")
                    }
                    if viewModel.attendeeCount > 0 {
                        Text(viewModel.attendeeCount == 1
                             ? "1 inscrito até agora. A capacidade não pode ser menor."
                             : "\(viewModel.attendeeCount) inscritos até agora. A capacidade não pode ser menor.")
                            .font(AppFont.legenda)
                            .foregroundStyle(AppColor.textoSecondario)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .font(AppFont.corpo)
            .foregroundStyle(AppColor.textoPrimario)
            .eventCardStyle()
            .animation(.default, value: viewModel.isUnlimitedCapacity)
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Preço")
            VStack(spacing: 12) {
                Toggle("Evento gratuito", isOn: $viewModel.isFree)
                    .tint(AppColor.primaria)
                if !viewModel.isFree {
                    HStack(spacing: 8) {
                        Text("R$").foregroundStyle(AppColor.textoSecondario)
                        TextField("0,00", text: $viewModel.priceText,
                                  prompt: Text("0,00").foregroundStyle(AppColor.placeholder))
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .font(AppFont.corpo)
            .foregroundStyle(AppColor.textoPrimario)
            .eventCardStyle()
            .animation(.default, value: viewModel.isFree)

            if let error = viewModel.priceError {
                Text(error)
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.erro)
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Categorias")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        CategoryChip(
                            title: category.name,
                            isSelected: viewModel.selectedCategoryIds.contains(category.id),
                            action: { viewModel.toggleCategory(category) }
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var dangerSection: some View {
        if viewModel.isEditing {
            if viewModel.originalStatus == .draft {
                dangerButton("Excluir rascunho") { showDeleteAlert = true }
            } else if viewModel.originalStatus == .published {
                dangerButton("Cancelar evento") { showCancelAlert = true }
            }
        }
    }

    private func dangerButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(AppFont.rotulo)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(AppColor.destrutiva, in: Capsule())
        .disabled(viewModel.isSaving)
        .padding(.top, 8)
    }
}

private extension View {
    func eventFieldStyle(hasError: Bool = false) -> some View {
        self
            .font(AppFont.corpo)
            .foregroundStyle(AppColor.textoPrimario)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppColor.clicavel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(hasError ? AppColor.erro : Color.clear, lineWidth: 1.5)
            )
    }

    func eventCardStyle() -> some View {
        self
            .padding(14)
            .background(AppColor.cards, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
