import SwiftUI

struct UpdateAlertView: View {
    let currentVersion: String
    let latestVersion: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Nueva versión disponible")
                .font(TextStyles.heading)
            
            Text("Hay una nueva versión (\(latestVersion)) disponible de la aplicación. Tu versión actual es \(currentVersion)")
                .font(TextStyles.bodyText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button("Actualizar ahora") {
                    if let url = URL(string: "itms-apps://apple.com/app/id[TU-APP-ID]") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Más tarde") {
                    isPresented = false
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.top)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .frame(minWidth: 200)
            .padding()
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
    }
} 