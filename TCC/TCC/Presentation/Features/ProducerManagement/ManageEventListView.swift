
import SwiftUI

struct ManageEventListView: View {
    @StateObject private var viewModel: ManageEventVM
    @EnvironmentObject private var session: SessionStore
    @State private var showCreate = false
    let router: Router

    init(viewModel: ManageEventVM, router: Router) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.router = router
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.hasLoaded && !viewModel.events.isEmpty {
                    segmentPicker
                }
                if let message = viewModel.errorMessage, !viewModel.events.isEmpty {
                    Text(message)
                        .font(AppFont.legenda)
                        .foregroundStyle(AppColor.erro)
                }
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(AppColor.fundo.ignoresSafeArea())
        .navigationTitle("Meus eventos")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { addButton }
        }
        .refreshable { await reload() }
        .task(id: session.currentProfile?.id) { await reload() }
        .onAppear {
            if viewModel.hasLoaded { Task { await reload() } }
        }
        .sheet(isPresented: $showCreate) {
            EventFormView(onSaved: { Task { await reload() } })
        }
    }

    private func reload() async {
        guard let producerId = session.currentProfile?.id else {
            viewModel.reset()
            return
        }
        await viewModel.load(producerId: producerId)
    }

    private var segmentPicker: some View {
        Picker("Período", selection: $viewModel.segment) {
            ForEach(ManageEventSegment.allCases) { segment in
                Text(segment.title).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    private var addButton: some View {
        Button { showCreate = true } label: {
            Image(systemName: "plus")
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColor.primaria)
        .accessibilityLabel("Criar evento")
    }

    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage, viewModel.events.isEmpty {
            errorState(message)
        } else if !viewModel.hasLoaded {
            ProgressView()
                .tint(AppColor.primaria)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if viewModel.events.isEmpty {
            emptyState
        } else if viewModel.visibleEvents.isEmpty {
            Text(viewModel.segment == .upcoming ? "Nenhum evento próximo." : "Nenhum evento encerrado.")
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.textoSecondario)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.visibleEvents) { event in
                    Button { router.push(.eventDetail(event)) } label: {
                        ManageEventCardView(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 15) {
            Image(systemName: "ticket")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AppColor.textMuted)
            Text("Você ainda não criou eventos")
                .font(AppFont.tituloSecao)
                .foregroundStyle(AppColor.textoPrimario)
                .multilineTextAlignment(.center)
            Button { showCreate = true } label: {
                Text("Criar meu primeiro evento")
                    .font(AppFont.rotulo)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppColor.primaria, in: Capsule())
            }
            .padding(.top, 15)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 150)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.erro)
                .multilineTextAlignment(.center)
            Button("Tentar de novo") {
                Task { await reload() }
            }
            .font(AppFont.rotulo)
            .foregroundStyle(AppColor.primaria)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

}
