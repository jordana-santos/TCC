
import SwiftUI

struct ManageEventCardView: View {
    let event: Event

    private var isCancelled: Bool { event.status == .cancelled }

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(AppFont.rotulo)
                    .foregroundStyle(isCancelled ? AppColor.textMuted : AppColor.textoPrimario)
                    .strikethrough(isCancelled)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(AppFont.metadado)
                    .foregroundStyle(AppColor.textoSecondario)
                    .lineLimit(1)

                ManageEventStatusBadge(status: event.status)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.textMuted)
        }
        .padding(12)
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
                ZStack {
                    AppColor.clicavel
                    Image(systemName: "ticket")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColor.textMuted)
                }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var subtitle: String {
        "\(dateText) · \(attendanceText)"
    }

    private var dateText: String {
        let parts = Calendar.current.dateComponents([.day, .hour, .minute], from: event.startsAt)
        let day = parts.day ?? 0
        let hour = parts.hour ?? 0
        let minute = parts.minute ?? 0
        let month = event.startsAt
            .formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "pt_BR")))
            .replacingOccurrences(of: ".", with: "")
            .capitalized
        let time = minute == 0 ? "\(hour)h" : "\(hour)h\(minute < 10 ? "0\(minute)" : "\(minute)")"
        return "\(day) \(month) · \(time)"
    }

    private var attendanceText: String {
        if let max = event.capacityMax {
            return "\(event.attendeeCount)/\(max)"
        }
        return "\(event.attendeeCount) inscritos"
    }
}

private struct ManageEventStatusBadge: View {
    let status: EventStatus

    private var label: String {
        switch status {
        case .published: return "Publicado"
        case .draft: return "Rascunho"
        case .cancelled: return "Cancelado"
        }
    }

    private var color: Color {
        switch status {
        case .published: return AppColor.successo
        case .draft: return AppColor.textoSecondario
        case .cancelled: return AppColor.erro
        }
    }

    var body: some View {
        Text(label)
            .font(AppFont.tag)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.18), in: Capsule())
    }
}
