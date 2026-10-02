import SwiftUI

struct EventListView: View {
    @StateObject private var viewModel: EventListVM
    @State private var showFilters = false
    let router: Router

    init(viewModel: EventListVM, router: Router) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                searchBar
                categoryChips
                eventsList
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 96)
        }
        .background(AppColor.fundo.ignoresSafeArea())
        .navigationTitle("Descobrir")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showFilters) {
            FiltersView(viewModel: viewModel)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(AppColor.textMuted)
                TextField("Buscar eventos", text: $viewModel.searchText)
                    .font(AppFont.corpo)
                    .foregroundStyle(AppColor.textoPrimario)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppColor.clicavel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: { showFilters = true }) {
                Image(systemName: "slider.horizontal.3")
                    .fontWeight(.bold)
                    .foregroundStyle(AppColor.textoPrimario)
                    .padding(12)
                    .background(AppColor.clicavel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var categoryChips: some View {
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

    @ViewBuilder
    private var eventsList: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.erro)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if viewModel.referenceState == .resolving
                    || (viewModel.isLoading && viewModel.events.isEmpty) {
            ProgressView()
                .tint(AppColor.primaria)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if viewModel.referenceState == .needsCity {
            cityPrompt
        } else if viewModel.filteredEvents.isEmpty {
            emptyState
        } else {
            VStack(spacing: 16) {
                ForEach(viewModel.filteredEvents) { event in
                    Button {
                        router.push(.eventDetail(event))
                    } label: {
                        EventCardView(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cityPrompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textMuted)
                .padding(20)
                .background(Circle().fill(AppColor.clicavel))
            Text("Onde você está?")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textoPrimario)
            Text("Sem a sua localização, precisamos da cidade para mostrar os eventos perto de você.")
                .font(AppFont.legenda)
                .foregroundStyle(AppColor.textoSecondario)
                .multilineTextAlignment(.center)
            CityFormView(buttonTitle: "Ver eventos") { city, state in
                try await viewModel.setCity(city: city, state: state)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "ticket")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textMuted)
                .padding(20)
                .background(Circle().fill(AppColor.clicavel))
            Text("Nenhum rolê por aqui")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textoPrimario)
            Text("Nenhum evento bate com esses filtros. Tente ampliar a distância ou trocar de categoria.")
                .font(AppFont.legenda)
                .foregroundStyle(AppColor.textoSecondario)
                .multilineTextAlignment(.center)
            Button("Limpar filtros") { viewModel.clearFilters() }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColor.textoPrimario)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
