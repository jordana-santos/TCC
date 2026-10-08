import Testing
import Foundation
@testable import TCC

// Usa Swift Testing. Se o seu TCCTests.swift usa XCTest, me avise que converto.
@MainActor
struct CalendarVMTests {
    private var calendar: Calendar {
        var c = Calendar.calendarioApp
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func event(_ title: String, at start: Date, status: EventStatus = .published) -> Event {
        Event(id: UUID(), title: title, description: "", startsAt: start,
              endsAt: start.addingTimeInterval(3600), price: 0, capacityMax: nil,
              attendeeCount: 0, externalLink: nil, imageURL: nil, status: status,
              producerId: UUID(),
              location: Location(address: "Lapa", latitude: 0, longitude: 0),
              categories: [])
    }

    private func makeVM(today: Date) -> CalendarVM {
        CalendarVM(calendar: calendar, now: { today })
    }

    @Test func agosto2025TemCincoCelulasVaziasE31Dias() {
        let vm = makeVM(today: date(2025, 8, 24))
        let days = vm.gridDays()
        #expect(vm.monthTitle == "Agosto 2025")
        #expect(days.prefix(while: { $0 == nil }).count == 5) // 1/ago/2025 é sexta
        #expect(days.compactMap { $0 }.count == 31)
    }

    @Test func iniciaNoDiaDeHojeSelecionado() {
        let vm = makeVM(today: date(2025, 8, 24, 15))
        #expect(vm.isSelected(date(2025, 8, 24)))
        #expect(vm.isToday(date(2025, 8, 24)))
    }

    @Test func pontinhosSoNosDiasComEvento() {
        let vm = makeVM(today: date(2025, 8, 24))
        let events = [event("A", at: date(2025, 8, 24, 22)), event("B", at: date(2025, 8, 27, 10))]
        let marked = vm.daysWithEvents(in: events)
        #expect(marked.count == 2)
        #expect(marked.contains(calendar.startOfDay(for: date(2025, 8, 27))))
        #expect(!marked.contains(calendar.startOfDay(for: date(2025, 8, 25))))
    }

    @Test func listaAgrupaPorDiaEOrdenaAPartirDoDiaSelecionado() {
        let vm = makeVM(today: date(2025, 8, 24))
        let events = [
            event("Depois", at: date(2025, 8, 27, 10)),
            event("Ontem", at: date(2025, 8, 23, 20)),
            event("Hoje 2", at: date(2025, 8, 24, 22)),
            event("Hoje 1", at: date(2025, 8, 24, 9)),
        ]
        let sections = vm.sections(for: events)
        #expect(sections.count == 2)
        #expect(sections[0].events.map(\.title) == ["Hoje 1", "Hoje 2"])
        #expect(sections[1].events.map(\.title) == ["Depois"])
        #expect(vm.header(for: sections[0].date) == "Dom, 24 Ago")
    }

    @Test func trocarDeMesMoveSelecaoParaODiaUmEExcluiEventosDeOutroMes() {
        let vm = makeVM(today: date(2025, 8, 24))
        let events = [event("Agosto", at: date(2025, 8, 27)), event("Setembro", at: date(2025, 9, 3))]
        vm.showNextMonth()
        #expect(vm.monthTitle == "Setembro 2025")
        #expect(vm.isSelected(date(2025, 9, 1)))
        #expect(vm.sections(for: events).flatMap(\.events).map(\.title) == ["Setembro"])
    }

    @Test func formataHorario() {
        let vm = makeVM(today: date(2025, 8, 24))
        #expect(vm.timeText(for: date(2025, 8, 24, 22)) == "22h")
        #expect(vm.timeText(for: date(2025, 8, 24, 19, 30)) == "19h30")
    }
}
