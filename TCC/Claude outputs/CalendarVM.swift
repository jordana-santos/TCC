import Foundation
import Combine

extension Calendar {
    /// Calendário gregoriano em pt_BR, semana começando no domingo (igual ao protótipo).
    static var calendarioApp: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
        calendar.firstWeekday = 1
        return calendar
    }
}

struct CalendarDaySection: Identifiable {
    let date: Date
    let events: [Event]
    var id: Date { date }
}

@MainActor
final class CalendarVM: ObservableObject {
    @Published private(set) var displayedMonth: Date
    @Published private(set) var selectedDate: Date

    let calendar: Calendar
    private let now: () -> Date

    private static let weekdayNames = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    private static let monthNames = [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]
    private static let monthAbbreviations = [
        "Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
        "Jul", "Ago", "Set", "Out", "Nov", "Dez"
    ]

    init(calendar: Calendar = .calendarioApp, now: @escaping () -> Date = Date.init) {
        let today = calendar.startOfDay(for: now())
        self.calendar = calendar
        self.now = now
        self.selectedDate = today
        self.displayedMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
    }

    // MARK: - Cabeçalho

    var monthTitle: String {
        let month = calendar.component(.month, from: displayedMonth)
        let year = calendar.component(.year, from: displayedMonth)
        return "\(Self.monthNames[month - 1]) \(year)"
    }

    var weekdayInitials: [String] {
        let base = ["D", "S", "T", "Q", "Q", "S", "S"]
        let shift = (calendar.firstWeekday - 1) % 7
        return Array(base[shift...] + base[..<shift])
    }

    // MARK: - Grade do mês

    /// Dias do mês exibido. `nil` são as células vazias antes do dia 1.
    func gridDays() -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count
        else { return [] }

        let first = interval.start
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            if let day = calendar.date(byAdding: .day, value: offset, to: first) {
                days.append(calendar.startOfDay(for: day))
            }
        }
        return days
    }

    func isSelected(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: selectedDate)
    }

    func isToday(_ day: Date) -> Bool {
        calendar.isDate(day, inSameDayAs: now())
    }

    func isPast(_ day: Date) -> Bool {
        day < calendar.startOfDay(for: now())
    }

    /// Dias (início do dia) que têm ao menos um evento. Usado nos pontinhos da grade.
    func daysWithEvents(in events: [Event]) -> Set<Date> {
        Set(events.map { calendar.startOfDay(for: $0.startsAt) })
    }

    // MARK: - Navegação

    func select(_ day: Date) {
        selectedDate = calendar.startOfDay(for: day)
    }

    func showNextMonth() { changeMonth(by: 1) }
    func showPreviousMonth() { changeMonth(by: -1) }

    func changeMonth(by value: Int) {
        guard let target = calendar.date(byAdding: .month, value: value, to: displayedMonth),
              let start = calendar.dateInterval(of: .month, for: target)?.start
        else { return }
        displayedMonth = start
        let today = calendar.startOfDay(for: now())
        selectedDate = calendar.isDate(today, equalTo: start, toGranularity: .month) ? today : start
    }

    // MARK: - Lista

    /// Eventos do dia selecionado em diante, até o fim do mês exibido, agrupados por dia.
    func sections(for events: [Event]) -> [CalendarDaySection] {
        guard let monthEnd = calendar.dateInterval(of: .month, for: displayedMonth)?.end else { return [] }
        let start = calendar.startOfDay(for: selectedDate)

        let visible = events
            .filter { $0.startsAt >= start && $0.startsAt < monthEnd }
            .sorted { $0.startsAt < $1.startsAt }

        let grouped = Dictionary(grouping: visible) { calendar.startOfDay(for: $0.startsAt) }
        return grouped.keys.sorted().map { CalendarDaySection(date: $0, events: grouped[$0] ?? []) }
    }

    /// Ex.: "Sáb, 24 Ago"
    func header(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        return "\(Self.weekdayNames[weekday - 1]), \(day) \(Self.monthAbbreviations[month - 1])"
    }

    /// Ex.: "22h" ou "19h30"
    func timeText(for date: Date) -> String {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return minute == 0 ? "\(hour)h" : "\(hour)h" + String(format: "%02d", minute)
    }
}
