struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 44, minHeight: 44) // Asegura tamaño mínimo
            .contentShape(Rectangle()) // Mejora área táctil
    }
} 