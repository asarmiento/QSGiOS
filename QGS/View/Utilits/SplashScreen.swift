//
//  SplashScreen.swift
//  QGS
//
//  Created by Edin Martinez on 8/11/24.
//
import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.5
    @State private var opacity = 0.5
    @State private var isUserValid = false
    @State private var isLoading = true

    // Version check states
    @State private var requiresUpdate = false
    @State private var currentVersion = ""
    @State private var latestVersion = ""
    @State private var versionCheckCompleted = false

    var body: some View {
        Group {
            if requiresUpdate {
                // Show blocking update required view
                UpdateRequiredView(
                    currentVersion: currentVersion,
                    latestVersion: latestVersion,
                    appStoreURL: AppConfigurationManager.shared.current.appStoreURL
                )
            } else if isActive {
                if isUserValid {
                    MainTabView()
                } else {
                    Login()
                }
            } else {
                splashContent
            }
        }
    }

    private var splashContent: some View {
        VStack {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 200)
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1
                        self.opacity = 1.0
                    }
                }

            // Show loading indicator while checking
            if !versionCheckCompleted {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            performStartupChecks()
        }
    }

    private func performStartupChecks() {
        Task {
            // Check for app update first
            await checkForUpdate()

            // Only proceed if no update is required
            if !requiresUpdate {
                // Validate user session - check token in Keychain first, then SwiftData
                let hasValidToken = UserManager.shared.getAuthToken != nil && !(UserManager.shared.getAuthToken?.isEmpty ?? true)
                let hasEmployeeId = UserManager.shared.getEmployeeId != nil && !(UserManager.shared.getEmployeeId?.isEmpty ?? true)

                // User is valid if we have a token AND employee ID (from Keychain/UserDefaults)
                // OR if user exists in SwiftData (backward compatibility)
                UserManager.shared.userExists { existsInDB in
                    DispatchQueue.main.async {
                        self.isUserValid = (hasValidToken && hasEmployeeId) || existsInDB
                        self.isLoading = false

                        // Transition after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func checkForUpdate() async {
        do {
            let result = try await VersionCheckService.shared.checkForUpdate()

            await MainActor.run {
                self.currentVersion = result.currentVersion
                self.latestVersion = result.latestVersion
                self.versionCheckCompleted = true

                if result.needsUpdate {
                    logInfo("App update required", category: .general, metadata: [
                        "currentVersion": result.currentVersion,
                        "latestVersion": result.latestVersion
                    ])

                    withAnimation {
                        self.requiresUpdate = true
                    }
                } else {
                    logInfo("App is up to date", category: .general, metadata: [
                        "version": result.currentVersion
                    ])
                }
            }
        } catch {
            // If version check fails, allow the app to continue
            // (don't block users if the server is down)
            await MainActor.run {
                self.versionCheckCompleted = true
                logWarning("Version check failed, allowing app to continue", category: .network, metadata: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
}

#Preview {
    SplashScreen()
}
