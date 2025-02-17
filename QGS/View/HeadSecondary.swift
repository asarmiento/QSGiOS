import SwiftUI

struct HeadSecondary: View {
    var title: String

    var body: some View {
        HStack {
            Menu {
                Button("Opción 1") {
                    // Acción para Opción 1
                }
                Button("Opción 2") {
                    // Acción para Opción 2
                }
            } label: {
                Label("Opciones", systemImage: "ellipsis.circle")
                    .font(.title2)
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Alinear a la izquierda

            Spacer()

            Text(title)
                .font(.headline)
                .padding()
        }
        .padding()
        .background(Color(.systemGray6))
    }
} 