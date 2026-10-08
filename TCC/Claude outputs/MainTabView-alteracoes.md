# Alterações no MainTabView.swift

Quatro trechos. Nada além disso muda nos arquivos existentes.

## 1. Novo router (junto dos outros @StateObject)

```swift
@StateObject private var calendarRouter = Router()
```

## 2. Aba Calendário do participante (em `attendeeTabs`)

Troque:

```swift
Text("Calendário")
    .tabItem { Label("Calendário", systemImage: "calendar") }
    .tag(AppTab.calendar)
```

por:

```swift
NavigationStack(path: $calendarRouter.path) {
    CalendarView(
        mode: .attendee,
        events: eventListViewModel.events.filter { engagementStore.isGoing($0.id) },
        router: calendarRouter
    )
    .navigationDestination(for: AppRoute.self, destination: destinationView)
}
.tabItem { Label("Calendário", systemImage: "calendar") }
.tag(AppTab.calendar)
```

## 3. Aba Calendário do produtor (em `producerTabs`)

Mesma troca, com:

```swift
CalendarView(
    mode: .producer,
    events: manageEventsViewModel.events,
    router: calendarRouter
)
```

## 4. Recarregar ao entrar na aba (no `.onChange(of: selectedTab)`)

Troque o bloco atual por:

```swift
.onChange(of: selectedTab) { _, tab in
    if tab == .discover || tab == .map {
        Task { await eventListViewModel.refresh() }
    }
    if tab == .calendar {
        if isProducer, let producerId = session.currentProfile?.id {
            Task { await manageEventsViewModel.load(producerId: producerId) }
        } else {
            Task { await eventListViewModel.refresh() }
        }
    }
}
```
