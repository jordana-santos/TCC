import SwiftUI

struct EventDetailView: View {
    @StateObject private var viewModel: EventDetailVM
    @EnvironmentObject private var engagementStore: EngagementStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionStore
    private var isGoing: Bool { engagementStore.isGoing(event.id) }
    private var hasCheckedIn: Bool { engagementStore.hasCheckedIn(event.id) }
    @State private var showEdit = false
    @State private var wasDeleted = false

    init(viewModel: EventDetailVM) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var event: Event { viewModel.event }
    private var canEdit: Bool {
        session.currentProfile?.id == event.producerId && event.status != .cancelled
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                imageHeader
                content
            }
        }
        .background(AppColor.fundo.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { actionBar }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.refresh() }
        .sheet(isPresented: $showEdit, onDismiss: {
            if wasDeleted { dismiss() }
        }) {
            EventFormView(
                mode: .edit(event),
                onSaved: { Task { await viewModel.refresh() } },
                onDeleted: { wasDeleted = true }
            )
        }
    }

    private var imageHeader: some View {
        ZStack(alignment: .top) {
            AsyncImage(url: URL(string: event.imageURL ?? "")) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Rectangle().fill(AppColor.clicavel)
                }
            }
            .frame(height: 280)
            .clipped()

            HStack {
                circleButton(systemName: "chevron.left") { dismiss() }
                Spacer()
                if canEdit {
                    circleButton(systemName: "pencil") { showEdit = true }
                }
                circleButton(
                    systemName: engagementStore.isFavorited(event.id) ? "heart.fill" : "heart",
                    tint: engagementStore.isFavorited(event.id) ? AppColor.neon : .white
                ) { session.requireAuth { engagementStore.toggleFavorite(event.id) } }
                circleButton(systemName: "square.and.arrow.up") { }
            }
            .padding(16)

            if let badge = capacityBadge {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(badge.text)
                            .font(AppFont.tag)
                            .foregroundStyle(badge.color)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.55), in: Capsule())
                    }
                }
                .padding(16)
            }
        }
    }

    private func circleButton(systemName: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .fontWeight(.bold)
                .foregroundStyle(tint)
                .padding(10)
                .background(.black.opacity(0.35), in: Circle())
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            if event.status != .published {
                statusBanner
            }
            badgesRow
            Text(event.title)
                .font(AppFont.tituloDetalhe)
                .foregroundStyle(AppColor.textoPrimario)
            metaRows
            if let capacityMax = event.capacityMax {
                capacitySection(max: capacityMax)
            }
            if isGoing && event.isFull {
                soldOutBanner
            }
            Text(event.description)
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.textoPrimario)
                .lineSpacing(8)

            if let link = event.externalLink, let url = URL(string: link) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("Página oficial do evento")
                    }
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.secundaria)
                }
            }

            if isGoing {
                goingStatus
            }
        }
        .padding(20)
    }

    private var badgesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(event.categories.sortedAlphabetically()) { category in
                    CategoryTagView(category: category)
                }
            }
        }
    }

    private var metaRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            metaRow(icon: "calendar", text: dateRangeText)
            metaRow(icon: "mappin.and.ellipse", text: event.location.address)
            metaRow(icon: "tag", text: priceText, tint: event.price == 0 ? AppColor.successo : AppColor.textoPrimario)
            metaRow(icon: "person.2", text: event.attendeeCount == 1 ? "1 pessoa vai" : "\(event.attendeeCount) pessoas vão")
        }
    }

    private func metaRow(icon: String, text: String, tint: Color = AppColor.textoPrimario) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.secundaria)
            Text(text)
                .font(AppFont.metadado)
                .foregroundStyle(tint)
        }
    }

    private func capacitySection(max: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Capacidade")
                    .font(AppFont.legenda)
                    .foregroundStyle(AppColor.textoSecondario)
                Spacer()
                if let remaining = event.remainingCapacity {
                    Text(event.isFull ? "esgotado" : "restam \(remaining) de \(max)")
                        .font(AppFont.legenda)
                        .foregroundStyle(event.isFull ? AppColor.destrutiva : AppColor.alerta)
                }
            }
            GeometryReader { geo in
                let ratio = max > 0 ? min(1, Double(event.attendeeCount) / Double(max)) : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(AppColor.primaria).frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 8)
        }
    }

    private var soldOutBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "nosign")
            Text("Evento lotado — inscrições encerradas")
                .font(AppFont.legenda)
        }
        .foregroundStyle(AppColor.erro)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.erro.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var goingStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
            Text(hasCheckedIn ? "Check-in feito" : "Você vai a este evento")
        }
        .font(AppFont.rotulo)
        .foregroundStyle(AppColor.successo)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(AppColor.successo.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var actionBar: some View {
        if event.status == .published && (!event.isFull || isGoing) {
            HStack(spacing: 12) {
                if !isGoing {
                    Button {
                        session.requireAuth { toggleGoing() }
                    } label: {
                        Text("Vou! · marcar presença")
                            .font(AppFont.rotulo)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .background(AppColor.primaria, in: Capsule())
                } else if !hasCheckedIn {
                    Button {
                        session.requireAuth { engagementStore.checkIn(event.id) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.key.fill")
                            Text("Fazer check-in")
                        }
                        .font(AppFont.rotulo)
                        .foregroundStyle(AppColor.fundo)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                    }
                    .background(AppColor.accent, in: Capsule())

                    Button {
                        toggleGoing()
                    } label: {
                        Text("Cancelar")
                            .font(AppFont.rotulo)
                            .foregroundStyle(AppColor.textoSecondario)
                            .padding(.vertical, 15)
                            .padding(.horizontal, 18)
                    }
                    .background(AppColor.clicavel, in: Capsule())
                }
            }
            .padding(16)
            .background(AppColor.fundo)
        }
    }

    private func toggleGoing() {
        Task {
            if await engagementStore.toggleGoing(event) {
                await viewModel.refresh()
            }
        }
    }

    private var dateRangeText: String {
        let weekday = event.startsAt.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "pt_BR")))
        let day = event.startsAt.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "pt_BR")))
        let start = event.startsAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "pt_BR")))
        let end = event.endsAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "pt_BR")))
        return "\(weekday), \(day) · \(start) – \(end)"
    }

    private var priceText: String {
        event.price == 0 ? "Gratuito" : event.price.formatted(.currency(code: "BRL"))
    }

    private var capacityBadge: (text: String, color: Color)? {
        if event.isFull { return ("Lotado", AppColor.destrutiva) }
        if let remaining = event.remainingCapacity, let max = event.capacityMax, max > 0,
           Double(remaining) / Double(max) <= 0.2 {
            return ("Quase cheio", AppColor.alerta)
        }
        return nil
    }
    
    private var statusBanner: some View {
        let isCancelled = event.status == .cancelled
        let color = isCancelled ? AppColor.erro : AppColor.alerta
        return HStack(spacing: 8) {
            Image(systemName: isCancelled ? "xmark.circle.fill" : "eye.slash.fill")
            Text(isCancelled ? "Evento cancelado" : "Rascunho, só você vê este evento")
                .font(AppFont.legenda)
        }
        .foregroundStyle(color)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
