import SwiftUI

struct EventCardView: View {
    let event: Event
    @EnvironmentObject private var engagementStore: EngagementStore
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            infoSection
        }
        .background(AppColor.cards)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var imageSection: some View {
        ZStack(alignment: .top) {
            AsyncImage(url: URL(string: event.imageURL ?? "")) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Rectangle().fill(AppColor.clicavel)
                }
            }
            .frame(height: 160)
            .clipped()

            HStack {
                Button(action: {session.requireAuth {engagementStore.toggleFavorite(event.id)}}) {
                    Image(systemName: engagementStore.isFavorited(event.id) ? "heart.fill" : "heart")
                        .fontWeight(.bold)
                        .foregroundStyle(engagementStore.isFavorited(event.id) ? AppColor.neon : .white)
                        .padding(8)
                        .background(.black.opacity(0.35), in: Circle())
                }
                Spacer()
                if let badge = capacityBadge {
                    Text(badge.text)
                        .font(AppFont.tag)
                        .foregroundStyle(badge.color)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.55), in: Capsule())
                }
            }
            .padding(10)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            categoriesRow

            Text(event.title)
                .font(AppFont.tituloCard)
                .foregroundStyle(AppColor.textoPrimario)

            Text(subtitle)
                .font(AppFont.metadado)
                .foregroundStyle(AppColor.textoSecondario)
        }
        .padding(16)
    }

    private var categoriesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(event.categories.sortedAlphabetically()) { category in
                    CategoryTagView(category: category)
                }
            }
        }
    }

    private var subtitle: String {
        let weekday = event.startsAt.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "pt_BR")))
        let day = event.startsAt.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "pt_BR")))
        let hour = event.startsAt.formatted(.dateTime.hour().minute().locale(Locale(identifier: "pt_BR")))
        return "\(weekday) · \(day) · \(hour)"
    }

    private var capacityBadge: (text: String, color: Color)? {
        if event.isFull { return ("Lotado", AppColor.destrutiva) }
        if let remaining = event.remainingCapacity, let max = event.capacityMax, max > 0,
           Double(remaining) / Double(max) <= 0.2 {
            return ("Quase cheio", AppColor.alerta)
        }
        return nil
    }
}
