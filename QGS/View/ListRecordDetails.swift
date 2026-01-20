//
//  ListRecordDetails.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//
import Foundation
import SwiftUI
import SwiftData

struct ListRecordDetails: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var networkListDetails = NetworkListDetails()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Use unified header
                UnifiedHeaderView(
                    title: "Detalle de Horas",
                    subtitle: "Registro diario de entradas y salidas"
                )
                
                if networkListDetails.isLoading {
                    // Use themed loading view
                    ThemedLoadingView(message: "Cargando registros...")
                        .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
                        .environmentObject(themeManager)
                } else if let errorMessage = networkListDetails.errorMessage {
                    // Use themed empty state for errors
                    ThemedEmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Error al cargar",
                        message: errorMessage,
                        action: {
                            networkListDetails.fetchWorkEntries()
                        },
                        actionTitle: "Reintentar"
                    )
                    .environmentObject(themeManager)
                } else {
                    if !networkListDetails.workEntries.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(networkListDetails.workEntries) { workEntry in
                                    WorkEntryCard(workEntry: workEntry)
                                        .environmentObject(themeManager)
                                }
                            }
                            .padding()
                        }
                        .background(themeManager.currentTheme.backgroundColor)
                    } else {
                        // Use themed empty state
                        ThemedEmptyStateView(
                            icon: "clock.badge.xmark",
                            title: "Sin registros",
                            message: "No hay entradas y salidas registradas para mostrar",
                            action: {
                                networkListDetails.fetchWorkEntries()
                            },
                            actionTitle: "Actualizar"
                        )
                        .environmentObject(themeManager)
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .onAppear {
                networkListDetails.context = modelContext
                networkListDetails.fetchWorkEntries()
                logInfo("ListRecordDetails appeared", category: .ui, metadata: [
                    "entries_count": networkListDetails.workEntries.count
                ])
            }
        }
        .environmentObject(themeManager)
    }
}

// MARK: - Work Entry Card Component
struct WorkEntryCard: View {
    let workEntry: WorkEntryDetails
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Project header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                    .font(.system(size: 16))
                
                Text(workEntry.project.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Type badge
                Text(workEntry.type.uppercased())
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        workEntry.type.lowercased() == "entrada" ?
                        themeManager.currentTheme.successColor.opacity(0.2) :
                        themeManager.currentTheme.warningColor.opacity(0.2)
                    )
                    .foregroundColor(
                        workEntry.type.lowercased() == "entrada" ?
                        themeManager.currentTheme.successColor :
                        themeManager.currentTheme.warningColor
                    )
                    .cornerRadius(themeManager.currentTheme.cornerRadius.small)
            }
            
            Divider()
                .background(themeManager.currentTheme.secondaryColor.opacity(0.2))
            
            // Details grid
            HStack(spacing: 20) {
                // Date
                VStack(alignment: .leading, spacing: 4) {
                    Label("Fecha", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                    
                    Text(workEntry.date)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Time
                VStack(alignment: .leading, spacing: 4) {
                    Label("Hora", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                    
                    Text(workEntry.time)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Hours
                if let hours = workEntry.hours {
                    VStack(alignment: .trailing, spacing: 4) {
                        Label("Horas", systemImage: "timer")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryColor)
                        
                        Text(String(format: "%.2f", hours))
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.surfaceColor)
        .cornerRadius(themeManager.currentTheme.cornerRadius.medium)
        .shadow(
            color: Color.black.opacity(themeManager.currentTheme.shadowStyle.light.opacity),
            radius: themeManager.currentTheme.shadowStyle.light.radius,
            y: 2
        )
    }
}

#Preview{
    ListRecordDetails()
}




