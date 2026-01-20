//
//  NetworkListTotal.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/2/24.
//  Modernized and optimized for better performance and error handling
//

import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
class NetworkListTotal: ObservableObject {
    @Published var totalHours = [TotalWorkEntry]()
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    var context: ModelContext?
    
    init() {
        logInfo("NetworkListTotal initialized", category: .network)
    }
    
    func fetchWorkEntries() async {
        await performFetch()
    }
    
    private func performFetch() async {
        guard let employeeId = getEmployeeId(),
              let authToken = getAuthToken() else {
            await handleError(AppNetworkError.unauthorized.toAppError())
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            logInfo("Fetching weekly totals", category: .network, metadata: [
                "employeeId": employeeId
            ])
            
            let config = RequestConfiguration(
                endpoint: .weeklyTotals(employeeId),
                method: .GET,
                requiresAuth: true
            )
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // TODO: Add caching support later
            logInfo("Fetching fresh weekly totals data", category: .network)
            
            // Fetch fresh data
            let response: [TotalWorkEntry] = try await SecureNetworkManager.shared.performRequest(
                config,
                responseType: [TotalWorkEntry].self
            )
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            totalHours = response
            isLoading = false
            
            // TODO: Cache the response when caching is available
            
            logInfo("Weekly totals fetched successfully", category: .network, metadata: [
                "count": response.count,
                "duration": "\(Int(duration * 1000))ms"
            ])
            
            // Analytics tracking for successful fetch
            logInfo("Network request completed", category: .network, metadata: [
                "endpoint": config.endpoint.rawValue,
                "duration": "\(Int(duration * 1000))ms"
            ])
            
        } catch {
            await handleError(error)
        }
    }
    
    private func handleError(_ error: Error) async {
        isLoading = false
        
        // Handle the error using ErrorManager
        ErrorManager.shared.handle(error, context: "NetworkListTotal.fetchWorkEntries")
        
        // Set user-friendly error message
        errorMessage = error.localizedDescription
        
        logError("Failed to fetch weekly totals", category: .network, metadata: [
            "error": error.localizedDescription
        ])
    }
    
    private func getAuthToken() -> String? {
        return UserManager.shared.getAuthToken
    }
    
    private func getEmployeeId() -> String? {
        return UserManager.shared.getEmployeeId
    }
    
    // MARK: - Manual Refresh
    func refreshData() async {
        await performFetch()
    }
    
    // MARK: - Clear Cache (TODO: Implement when caching is available)
    func clearCache() async {
        logInfo("Cache clearing not implemented yet", category: .network)
    }
}


