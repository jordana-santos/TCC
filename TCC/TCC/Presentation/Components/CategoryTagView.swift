import SwiftUI

struct CategoryTagView: View {
    let category: Category

    var body: some View {
        let style = Self.style(for: category)
        Text(category.name.uppercased())
            .font(AppFont.tag)
            .foregroundStyle(style.text)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(style.background, in: Capsule())
    }

    static func style(for category: Category) -> (background: Color, text: Color) {
        switch category.name.lowercased() {
        case "show":
            return (AppColor.secundaria, AppColor.fundo)
        case "teatro":
            return (AppColor.accent.opacity(0.18), AppColor.accent)
        case "exposição", "exposicao":
            return (AppColor.neon.opacity(0.18), AppColor.neon)
        default:
            let palette: [Color] = [AppColor.secundaria, AppColor.accent, AppColor.neon]
            let bytes = withUnsafeBytes(of: category.id.uuid) { Array($0) }
            let base = palette[bytes.reduce(0) { $0 + Int($1) } % palette.count]
            return (base.opacity(0.18), base)
        }
    }
}
