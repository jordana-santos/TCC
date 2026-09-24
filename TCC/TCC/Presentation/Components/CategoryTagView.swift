import SwiftUI

struct CategoryTagView: View {
    let category: Category

    var body: some View {
        let style = CategoryTagView.style(for: category)
        HStack(spacing: 4) {
            Image(systemName: style.icon)
                .font(.system(size: 10, weight: .bold))
            Text(category.name)
                .font(AppFont.tag)
        }
        .foregroundStyle(style.text)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(style.background)
        .clipShape(Capsule())
    }

    static func style(for category: Category) -> (background: Color, text: Color, icon: String) {
        switch category.name.lowercased() {
        case "música", "musica":
            return (AppColor.secundaria.opacity(0.18), AppColor.textoMusica, "music.note")
        case "teatro":
            return (AppColor.accent.opacity(0.18), AppColor.textoTeatro, "theatermasks.fill")
        case "arte e exposições", "arte e exposicoes":
            return (AppColor.neon.opacity(0.18), AppColor.textoArte, "paintpalette.fill")
        case "gastronomia":
            return (AppColor.gastronomia.opacity(0.18), AppColor.textoGastronomia, "fork.knife")
        default:
            return (AppColor.cards, AppColor.textoSecondario, "tag.fill")
        }
    }
}
