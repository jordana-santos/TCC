
import SwiftUI

struct EventListView: View {
    @StateObject private var viewModel: EventListVM

    init(viewModel: EventListVM) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                searchBar
                categoryChips
                eventsList
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 96)
        }
        .background(AppColor.fundo.ignoresSafeArea())
        .task { await viewModel.load() }
    }

    private var header: some View {
        HStack {
            Text("Descobrir")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(AppColor.textoPrimario)
            Spacer()
            Circle()
                .fill(AppColor.primaria)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("MR")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )
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

            Button(action: {}) {
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
        } else if viewModel.isLoading && viewModel.events.isEmpty {
            ProgressView()
                .tint(AppColor.primaria)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if viewModel.filteredEvents.isEmpty {
            emptyState
        } else {
            VStack(spacing: 16) {
                ForEach(viewModel.filteredEvents) { event in
                    EventCardView(event: event)
                }
            }
        }
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
