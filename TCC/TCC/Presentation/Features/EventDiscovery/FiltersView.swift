
import SwiftUI

struct FiltersView: View {
    @ObservedObject var viewModel: EventListVM
    @Environment(\.dismiss) private var dismiss
    @State private var dateFilterEnabled: Bool

    init(viewModel: EventListVM) {
        self.viewModel = viewModel
        _dateFilterEnabled = State(initialValue: viewModel.selectedDate != nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    categorySection
                    dateSection
                    priceSection
                    distanceSection
                    locationSection
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(AppColor.fundo.ignoresSafeArea())
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Limpar") { viewModel.clearFilters() }
                        .foregroundStyle(AppColor.textoSecondario)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(AppColor.primaria)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categoria")
                .font(AppFont.tituloSecao)
                .foregroundStyle(AppColor.textoPrimario)
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

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Data")
                    .font(AppFont.tituloSecao)
                    .foregroundStyle(AppColor.textoPrimario)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { dateFilterEnabled },
                    set: { newValue in
                        dateFilterEnabled = newValue
                        viewModel.selectedDate = newValue ? (viewModel.selectedDate ?? .now) : nil
                    }
                ))
                .labelsHidden()
                .tint(AppColor.primaria)
            }
            if dateFilterEnabled {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.selectedDate ?? .now },
                        set: { viewModel.selectedDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(AppColor.primaria)
                .environment(\.locale, Locale(identifier: "pt_BR"))
            }
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preço")
                .font(AppFont.tituloSecao)
                .foregroundStyle(AppColor.textoPrimario)
            Toggle(isOn: $viewModel.freeOnly) {
                Text("Somente eventos gratuitos")
                    .font(AppFont.corpo)
                    .foregroundStyle(AppColor.textoPrimario)
            }
            .tint(AppColor.primaria)

            if !viewModel.freeOnly {
                HStack {
                    Text("Preço máximo")
                        .font(AppFont.corpo)
                        .foregroundStyle(AppColor.textoPrimario)
                    Spacer()
                    TextField("Sem limite", value: Binding(
                        get: { viewModel.maxPrice ?? 0 },
                        set: { viewModel.maxPrice = $0 == 0 ? nil : $0 }
                    ), format: .currency(code: "BRL"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(AppColor.textoPrimario)
                        .frame(width: 120)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppColor.clicavel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distância")
                .font(AppFont.tituloSecao)
                .foregroundStyle(AppColor.textoPrimario)
            VStack(alignment: .leading, spacing: 6) {
                Text("Até \(Int(viewModel.radiusKm)) km")
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.textoSecondario)
                Slider(value: $viewModel.radiusKm, in: 1...50, step: 1)
                    .tint(AppColor.primaria)
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Localização")
                .font(AppFont.tituloSecao)
                .foregroundStyle(AppColor.textoPrimario)
            if let label = viewModel.referenceLabel {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(AppColor.textMuted)
                    Text("Perto de: \(label)")
                        .font(AppFont.corpo)
                        .foregroundStyle(AppColor.textoPrimario)
                }
            }
            CityFormView(buttonTitle: "Trocar cidade", initialState: viewModel.suggestedState) { city, state in
                try await viewModel.setCity(city: city, state: state)
            }
        }
    }
}
