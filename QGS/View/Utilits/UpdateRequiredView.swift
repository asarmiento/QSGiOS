//
//  UpdateRequiredView.swift
//  QGS
//
//  Created by Assistant on 2026-01-20.
//
//  Purpose: Blocking view that forces users to update the app
//  before they can continue using it.
//

import SwiftUI

struct UpdateRequiredView: View {
    let currentVersion: String
    let latestVersion: String
    let appStoreURL: String

    @StateObject private var themeManager = ThemeManager.shared
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.currentTheme.primaryColor.opacity(0.1),
                    themeManager.currentTheme.backgroundColor
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Update icon with animation
                ZStack {
                    Circle()
                        .fill(themeManager.currentTheme.primaryColor.opacity(0.1))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(themeManager.currentTheme.primaryColor.opacity(0.2))
                        .frame(width: 110, height: 110)

                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }

                // Title
                Text("Actualización Requerida")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                // Description
                Text("Hay una nueva versión de la aplicación disponible. Por favor actualiza para continuar usando la app.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Version info card
                VStack(spacing: 12) {
                    HStack {
                        Text("Tu versión:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currentVersion)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }

                    Divider()

                    HStack {
                        Text("Nueva versión:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(latestVersion)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(themeManager.currentTheme.surfaceColor)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                .padding(.horizontal, 32)

                Spacer()

                // Update button
                Button(action: openAppStore) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                        Text("Actualizar Ahora")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeManager.currentTheme.primaryColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 16)

                // App Store badge
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                        .font(.caption)
                    Text("Disponible en App Store")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            isAnimating = true
        }
        .interactiveDismissDisabled(true) // Prevent dismissing
    }

    private func openAppStore() {
        guard let url = URL(string: appStoreURL) else {
            // Fallback to general App Store search
            if let fallbackURL = URL(string: "https://apps.apple.com/app/id6504676498") {
                UIApplication.shared.open(fallbackURL)
            }
            return
        }
        UIApplication.shared.open(url)
    }
}

#Preview {
    UpdateRequiredView(
        currentVersion: "1.0.0",
        latestVersion: "2.0.0",
        appStoreURL: "https://apps.apple.com/app/id6504676498"
    )
}
