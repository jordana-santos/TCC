import SwiftUI

enum AppFont {
    /// Heavy 800 · 30pt. Telas de boas-vindas / onboarding.
    static let display = Font.system(size: 30, weight: .heavy, design: .rounded)
    /// Bold 700 · 21pt. Título de seção dentro da tela.
    static let tituloSecao = Font.system(size: 21, weight: .bold, design: .rounded)
    /// Heavy 800 · 18pt. Título dentro de um card de evento.
    static let tituloCard = Font.system(size: 18, weight: .heavy, design: .rounded)
    /// Bold 700 · 17pt. Nav title e rótulo de botão.
    static let rotulo = Font.system(size: 17, weight: .bold, design: .rounded)
    /// Semibold 600 · 16pt. Subtítulo / headline de linha.
    static let subtitulo = Font.system(size: 16, weight: .semibold, design: .rounded)
    /// Regular 400 · 16pt · line-height 1,5. Corpo de texto.
    static let corpo = Font.system(size: 16, weight: .regular, design: .rounded)
    /// Medium 500 · 13pt. Legenda auxiliar.
    static let legenda = Font.system(size: 13, weight: .medium, design: .rounded)
    /// Mono · Medium 500 · 13pt. Metadado: data, hora, local.
    static let metadado = Font.system(size: 13, weight: .medium, design: .monospaced)
    /// Bold 700 · 11pt · caixa alta. Tag de categoria / micro label.
    static let tag = Font.system(size: 11, weight: .bold, design: .rounded)
}
