struct ContentSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Contenido agrupado lógicamente
            Text("Título")
                .font(.headline)
            
            // Controles cercanos al contenido relacionado
            HStack {
                TextField("Entrada", text: $input)
                Button("Editar") {
                    // acción
                }
            }
        }
    }
} 