import SwiftUI

struct CalendarBadge {
    let text: String
    let color: Color
}

struct CalendarEventRow: View {
    let event: Event
    let timeText: String
    let badge: CalendarBadge?

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let category = event.categories.sortedAlphabetically().first {
                            Text(category.name.uppercased())
                                .font(AppFont.tag)
                                .foregroundStyle(CategoryTagView.style(for: category).text)
                        }
                        Text(event.title)
                            .font(AppFont.rotulo)
                            .foregroundStyle(AppColor.textoPrimario)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    if let badge {
                        Text(badge.text)
                            .font(AppFont.tag)
                            .foregroundStyle(badge.color)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(badge.color.opacity(0.18), in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(AppFont.metadado)
                    .foregroundStyle(AppColor.textoSecondario)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(AppColor.cards)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var thumbnail: some View {
        AsyncImage(url: URL(string: event.imageURL ?? "")) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                Rectangle().fill(AppColor.clicavel)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var subtitle: String {
        let place = event.location.address
            .split(separator: ",", maxSplits: 1)
            .first
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""
        return place.isEmpty ? timeText : "\(timeText) · \(place)"
    }}
