//
//  ListRecordTotals.swift
//  QGS
//
//  Created by Edin Martinez on 11/19/24.
//

import SwiftUI

struct ListRecordTotals: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var networkListTotal = NetworkListTotal()
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Use unified header
                UnifiedHeaderView(
                    title: "Total de Horas",
                    subtitle: "Resumen semanal de trabajo"
                )
                .environmentObject(themeManager)
                
                // Main content area
                Group {
                    if networkListTotal.isLoading {
                        // Use themed loading view
                        ThemedLoadingView(message: "Cargando totales semanales...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .environmentObject(themeManager)
                    } else if let errorMessage = networkListTotal.errorMessage {
                        // Use themed empty state for errors
                        ThemedEmptyStateView(
                            icon: "exclamationmark.triangle",
                            title: "Error al cargar datos",
                            message: errorMessage,
                            action: {
                                Task {
                                    await networkListTotal.fetchWorkEntries()
                                }
                            },
                            actionTitle: "Reintentar"
                        )
                        .environmentObject(themeManager)
                    } else {
                        weeklyTotalsContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            .onAppear {
                Task {
                    await loadData()
                }
            }
        }
        .environmentObject(themeManager)
    }
    
    @ViewBuilder
    private var weeklyTotalsContent: some View {
        if networkListTotal.totalHours.isEmpty {
            // Use themed empty state
            ThemedEmptyStateView(
                icon: "clock.badge.xmark",
                title: "Sin registros de horas",
                message: "No hay datos de horas semanales disponibles",
                action: {
                    Task {
                        await networkListTotal.fetchWorkEntries()
                    }
                },
                actionTitle: "Actualizar"
            )
            .environmentObject(themeManager)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(networkListTotal.totalHours.enumerated()), id: \.element.id) { index, totalHour in
                        WeeklyTotalCard(
                            totalHour: totalHour,
                            position: (index + 1, networkListTotal.totalHours.count)
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            .refreshable {
                await networkListTotal.fetchWorkEntries()
            }
        }
    }
    
    private func loadData() async {
        logInfo("Loading weekly totals data", category: .ui)
        await networkListTotal.fetchWorkEntries()
        
        if !networkListTotal.totalHours.isEmpty {
            logInfo("Weekly totals screen loaded", category: .ui, metadata: [
                "total_weeks": networkListTotal.totalHours.count
            ])
        }
    }
}

// MARK: - Weekly Total Card Component
struct WeeklyTotalCard: View {
    let totalHour: TotalWorkEntry
    let position: (Int, Int)?
    @StateObject private var themeManager = ThemeManager.shared
    
    private var hoursValue: Double {
        Double(totalHour.hours) ?? 0.0
    }
    
    private var formattedHours: String {
        let hours = Int(hoursValue)
        let minutes = Int((hoursValue - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    private var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        
        if let startDate = parseDate(totalHour.weekI),
           let endDate = parseDate(totalHour.weekF) {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
        return "\(totalHour.weekI) - \(totalHour.weekF)"
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Semana")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                    
                    Text(weekDateRange)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                    
                    Text(formattedHours)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                }
            }
            
            // Progress bar with theme colors
            UnifiedProgressIndicator(
                progress: min(hoursValue / 40.0, 1.0),
                title: nil,
                showPercentage: false
            )
            .environmentObject(themeManager)
            
            HStack {
                Text("\(String(format: "%.1f", hoursValue)) de 40 horas")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                
                Spacer()
                
                Text(progressPercentage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(progressColor(for: hoursValue))
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
        .accessibilityLabel("Total semanal: \(formattedHours) para la semana del \(weekDateRange)")
        .accessibilityHint("Información de horas trabajadas esta semana")
    }
    
    private var progressPercentage: String {
        let percentage = min((hoursValue / 40.0) * 100, 100)
        return "\(Int(percentage))%"
    }
    
    private func progressColor(for hours: Double) -> Color {
        switch hours {
        case 0..<20:
            return themeManager.currentTheme.warningColor
        case 20..<35:
            return Color.yellow
        case 35..<45:
            return themeManager.currentTheme.successColor
        default:
            return themeManager.currentTheme.primaryColor
        }
    }
}

#Preview {
    NavigationStack {
        ListRecordTotals()
    }
}
