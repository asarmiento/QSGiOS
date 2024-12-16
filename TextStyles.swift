struct TextStyles {
    static let bodyText = Font.system(size: 16)
    static let heading = Font.system(size: 20, weight: .bold)
    
    static let lineSpacing: CGFloat = 1.2
    static let letterSpacing: CGFloat = 0.5
}

// Implementación
Text("Contenido")
    .font(TextStyles.bodyText)
    .lineSpacing(TextStyles.lineSpacing)
    .tracking(TextStyles.letterSpacing) 