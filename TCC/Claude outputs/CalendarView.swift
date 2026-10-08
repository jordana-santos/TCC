import SwiftUI

struct CalendarView: View {
    enum Mode {
        case attendee   // eventos em que o usuário marcou "Vou"
        case producer   // eventos criados pelo produtor
    }

    let mode: Mode
    let events: [Event]
    let router: Router

    @StateObject private var viewModel = CalendarVM()
    @EnvironmentObject private var session: SessionStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Calendário")
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.textoPrimario)

                if session.isAuthenticated {
                    monthHeader
                    monthGrid
                    eventList
                } else {
                    loggedOutState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AppColor.fundo.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Mês

    private var monthHeader: some View {
        HStack {
            Text(viewModel.monthTitle)
                .font(AppFont.rotulo)
                .foregroundStyle(AppColor.textoPrimario)
            Spacer()
            Button { viewModel.showPreviousMonth() } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.bold)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Mês anterior")
            Button { viewModel.showNextMonth() } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.bold)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Próximo mês")
        }
        .foregroundStyle(AppColor.secundaria)
    }

    private var monthGrid: some View {
        let marked = viewModel.daysWithEvents(in: events)
        let days = viewModel.gridDays()

        return VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Array(viewModel.weekdayInitials.enumerated()), id: \.offset) { _, initial in
                    Text(initial)
                        .font(AppFont.metadado)
                        .foregroundStyle(AppColor.textoSecondario)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day, hasEvents: marked.contains(day))
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date, hasEvents: Bool) -> some View {
        let selected = viewModel.isSelected(day)
        let past = viewModel.isPast(day)
        let number = viewModel.calendar.component(.day, from: day)

        return Button { viewModel.select(day) } label: {
            VStack(spacing: 3) {
                ZStack {
                    if selected {
                        Circle().fill(AppColor.primaria)
                    } else if viewModel.isToday(day) {
                        Circle().strokeBorder(AppColor.primaria, lineWidth: 1.5)
                    }
                    Text("\(number)")
                        .font(selected ? AppFont.rotulo : AppFont.corpo)
                        .foregroundStyle(selected ? Color.white : (past ? AppColor.textMuted : AppColor.textoPrimario))
                }
                .frame(width: 36, height: 36)

                Circle()
                    .fill(hasEvents ? AppColor.secundaria : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(number)\(hasEvents ? ", com eventos" : "")")
    }

    // MARK: - Lista

    @ViewBuilder
    private var eventList: some View {
        let sections = viewModel.sections(for: events)

        if sections.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.header(for: section.date))
                            .font(AppFont.legenda)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColor.textoPrimario)

                        ForEach(section.events) { event in
                            Button { router.push(.eventDetail(event)) } label: {
                                CalendarEventRow(
                                    event: event,
                                    timeText: viewModel.timeText(for: event.startsAt),
                                    badge: badge(for: event)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func badge(for event: Event) -> CalendarBadge? {
        if event.status == .cancelled { return CalendarBadge(text: "Cancelado", color: AppColor.erro) }
        switch mode {
        case .attendee:
            return CalendarBadge(text: "Vou", color: AppColor.successo)
        case .producer:
            return event.status == .draft
                ? CalendarBadge(text: "Rascunho", color: AppColor.alerta)
                : CalendarBadge(text: "Publicado", color: AppColor.successo)
        }
    }

    // MARK: - Estados vazios

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 32))
                .foregroundStyle(AppColor.textMuted)
            Text(mode == .attendee ? "Nenhum evento marcado" : "Nenhum evento seu")
                .font(AppFont.subtitulo)
                .foregroundStyle(AppColor.textoPrimario)
            Text(mode == .attendee
                 ? "Marque \"Vou\" em um evento para vê-lo aqui, a partir do dia selecionado."
                 : "Seus eventos a partir do dia selecionado aparecem aqui.")
                .font(AppFont.legenda)
                .foregroundStyle(AppColor.textoSecondario)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    private var loggedOutState: some View {
        VStack(spacing: 14) {
            Text("Entre para ver seu calendário")
                .font(AppFont.corpo)
                .foregroundStyle(AppColor.textoSecondario)
            Button { session.isPresentingLogin = true } label: {
                Text("Entrar")
                    .font(AppFont.rotulo)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .background(AppColor.primaria, in: Capsule())
        }
        .padding(.top, 48)
    }
}
