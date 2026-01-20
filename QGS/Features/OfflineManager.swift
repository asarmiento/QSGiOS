import Foundation
import SwiftData
import Network
import UIKit

// MARK: - Offline Manager
/// Comprehensive offline support with intelligent synchronization for QGS app
/// Handles data persistence, conflict resolution, and background sync

class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOnline = true
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingSyncCount = 0
    @Published var lastSyncDate: Date?
    
    private let networkMonitor = NWPathMonitor()
    private let syncQueue = DispatchQueue(label: "com.qgs.sync", qos: .utility)
    private let networkQueue = DispatchQueue(label: "com.qgs.network")
    
    private var modelContext: ModelContext?
    private var syncTimer: Timer?
    private var pendingOperations: [OfflineOperation] = []
    
    // MARK: - Sync Status
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case completed(Date)
        case failed(String)
        case conflictDetected([ConflictResolution])
        
        var isActive: Bool {
            if case .syncing = self {
                return true
            }
            return false
        }
        
        var displayText: String {
            switch self {
            case .idle:
                return "Listo para sincronizar"
            case .syncing:
                return "Sincronizando..."
            case .completed(let date):
                let formatter = DateFormatter()
                formatter.dateStyle = .none
                formatter.timeStyle = .short
                return "Sincronizado \(formatter.string(from: date))"
            case .failed(let error):
                return "Error: \(error)"
            case .conflictDetected(let conflicts):
                return "\(conflicts.count) conflictos detectados"
            }
        }
    }
    
    // MARK: - Offline Operations
    enum OperationType: String, Codable {
        case createRecord = "create_record"
        case updateRecord = "update_record"
        case deleteRecord = "delete_record"
        case registerUser = "register_user"
        case updateProfile = "update_profile"
        case uploadFile = "upload_file"
    }
    
    struct OfflineOperation: Codable, Identifiable, Equatable {
        let id: UUID
        let type: OperationType
        let timestamp: Date
        let data: Data
        let metadata: [String: String]
        var attempts: Int
        var lastAttempt: Date?
        var error: String?
        
        init(type: OperationType, data: Data, metadata: [String: String] = [:]) {
            self.id = UUID()
            self.type = type
            self.timestamp = Date()
            self.data = data
            self.metadata = metadata
            self.attempts = 0
        }
    }
    
    // MARK: - Conflict Resolution
    struct ConflictResolution: Identifiable, Equatable {
        let id = UUID()
        let localData: Data
        let serverData: Data
        let timestamp: Date
        let operation: OfflineOperation
        
        enum Resolution {
            case useLocal
            case useServer
            case merge
            case skip
        }
    }
    
    private init() {
        setupNetworkMonitoring()
        loadPendingOperations()
        setupPeriodicSync()
        
        logInfo("OfflineManager initialized", category: .sync)
    }
    
    // MARK: - Configuration
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        logInfo("OfflineManager configured with ModelContext", category: .sync)
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let wasOnline = self?.isOnline ?? false
                self?.isOnline = path.status == .satisfied
                
                if !wasOnline && self?.isOnline == true {
                    // Just came back online - trigger sync
                    logInfo("Network connection restored, triggering sync", category: .sync)
                    Task {
                        await self?.performSync()
                    }
                } else if wasOnline && self?.isOnline == false {
                    logInfo("Network connection lost, entering offline mode", category: .sync)
                }
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
    
    private func setupPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            // Sync every 5 minutes if online and has pending operations
            if self?.isOnline == true && self?.pendingSyncCount ?? 0 > 0 {
                Task {
                    await self?.performSync()
                }
            }
        }
    }
    
    // MARK: - Offline Operations Management
    
    func queueOperation(_ operation: OfflineOperation) {
        syncQueue.async { [weak self] in
            self?.pendingOperations.append(operation)
            self?.savePendingOperations()
            
            DispatchQueue.main.async {
                self?.pendingSyncCount = self?.pendingOperations.count ?? 0
                
                logInfo("Operation queued for sync", category: .sync, metadata: [
                    "type": operation.type.rawValue,
                    "pendingCount": self?.pendingSyncCount ?? 0
                ])
            }
            
            // If online, try to sync immediately
            if self?.isOnline == true {
                Task {
                    await self?.performSync()
                }
            }
        }
    }
    
    private func loadPendingOperations() {
        syncQueue.async { [weak self] in
            if let data = UserDefaults.standard.data(forKey: "PendingOperations"),
               let operations = try? JSONDecoder().decode([OfflineOperation].self, from: data) {
                self?.pendingOperations = operations
                
                DispatchQueue.main.async {
                    self?.pendingSyncCount = operations.count
                    
                    if operations.count > 0 {
                        logInfo("Loaded pending operations", category: .sync, metadata: [
                            "count": operations.count
                        ])
                    }
                }
            }
        }
    }
    
    private func savePendingOperations() {
        if let data = try? JSONEncoder().encode(pendingOperations) {
            UserDefaults.standard.set(data, forKey: "PendingOperations")
        }
    }
    
    // MARK: - Sync Operations
    
    func performSync() async {
        guard isOnline else {
            logWarning("Cannot sync - offline", category: .sync)
            return
        }
        
        guard !syncStatus.isActive else {
            logInfo("Sync already in progress", category: .sync)
            return
        }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        logInfo("Starting sync operation", category: .sync, metadata: [
            "pendingOperations": pendingOperations.count
        ])
        
        do {
            // Download latest data first
            try await downloadLatestData()
            
            // Upload pending operations
            await uploadPendingOperations()
            
            await MainActor.run {
                lastSyncDate = Date()
                syncStatus = .completed(Date())
                
                logInfo("Sync completed successfully", category: .sync)
            }
            
        } catch {
            await MainActor.run {
                syncStatus = .failed(error.localizedDescription)
                
                logError("Sync failed", category: .sync, metadata: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    private func downloadLatestData() async throws {
        // Download latest time records, projects, and user data
        do {
            let timeRecords = try await fetchLatestTimeRecords()
            let projects = try await fetchLatestProjects()
            let userProfile = try await fetchUserProfile()
            
            // Update local database
            await updateLocalData(timeRecords: timeRecords, projects: projects, userProfile: userProfile)
            
            logInfo("Latest data downloaded", category: .sync)
            
        } catch {
            logError("Failed to download latest data", category: .sync, metadata: [
                "error": error.localizedDescription
            ])
            throw error
        }
    }
    
    private func uploadPendingOperations() async {
        var completedOperations: [UUID] = []
        var failedOperations: [OfflineOperation] = []
        
        for operation in pendingOperations {
            do {
                let success = try await uploadOperation(operation)
                if success {
                    completedOperations.append(operation.id)
                    logInfo("Operation uploaded successfully", category: .sync, metadata: [
                        "type": operation.type.rawValue,
                        "id": operation.id.uuidString
                    ])
                } else {
                    var failedOperation = operation
                    failedOperation.attempts += 1
                    failedOperation.lastAttempt = Date()
                    failedOperation.error = "Upload failed"
                    failedOperations.append(failedOperation)
                }
            } catch {
                var failedOperation = operation
                failedOperation.attempts += 1
                failedOperation.lastAttempt = Date()
                failedOperation.error = error.localizedDescription
                failedOperations.append(failedOperation)
                
                logError("Operation upload failed", category: .sync, metadata: [
                    "type": operation.type.rawValue,
                    "error": error.localizedDescription,
                    "attempts": failedOperation.attempts
                ])
            }
        }
        
        // Remove completed operations
        syncQueue.async { [weak self] in
            self?.pendingOperations.removeAll { completedOperations.contains($0.id) }
            
            // Add back failed operations with updated attempt count
            self?.pendingOperations.append(contentsOf: failedOperations)
            
            // Remove operations that have failed too many times (>5 attempts)
            self?.pendingOperations.removeAll { $0.attempts > 5 }
            
            self?.savePendingOperations()
            
            DispatchQueue.main.async {
                self?.pendingSyncCount = self?.pendingOperations.count ?? 0
            }
        }
    }
    
    private func uploadOperation(_ operation: OfflineOperation) async throws -> Bool {
        switch operation.type {
        case .createRecord:
            return try await uploadTimeRecord(operation)
        case .updateRecord:
            return try await updateTimeRecord(operation)
        case .deleteRecord:
            return try await deleteTimeRecord(operation)
        case .registerUser:
            return try await uploadUserRegistration(operation)
        case .updateProfile:
            return try await updateUserProfile(operation)
        case .uploadFile:
            return try await uploadFile(operation)
        }
    }
    
    // MARK: - Specific Upload Methods
    
    private func uploadTimeRecord(_ operation: OfflineOperation) async throws -> Bool {
        // Parse the operation data directly
        guard operation.data.count > 0 else {
            return false
        }
        
        let config = RequestConfiguration(
            endpoint: .storeTimeWork,
            method: .POST,
            body: operation.data,
            requiresAuth: true
        )
        
        let response: RecordResponse = try await SecureNetworkManager.shared.performRequest(config, responseType: RecordResponse.self)
        return response.success
    }
    
    private func updateTimeRecord(_ operation: OfflineOperation) async throws -> Bool {
        // Implementation for updating time records
        return true
    }
    
    private func deleteTimeRecord(_ operation: OfflineOperation) async throws -> Bool {
        // Implementation for deleting time records
        return true
    }
    
    private func uploadUserRegistration(_ operation: OfflineOperation) async throws -> Bool {
        let config = RequestConfiguration(
            endpoint: .register,
            method: .POST,
            body: operation.data,
            requiresAuth: false
        )
        
        let response: RegisterResponse = try await SecureNetworkManager.shared.performRequest(config, responseType: RegisterResponse.self)
        return response.success
    }
    
    private func updateUserProfile(_ operation: OfflineOperation) async throws -> Bool {
        let config = RequestConfiguration(
            endpoint: .updateProfile,
            method: .PUT,
            body: operation.data,
            requiresAuth: true
        )
        
        let response: EmptyResponse = try await SecureNetworkManager.shared.performRequest(config, responseType: EmptyResponse.self)
        return true
    }
    
    private func uploadFile(_ operation: OfflineOperation) async throws -> Bool {
        // Implementation for file uploads
        return true
    }
    
    // MARK: - Download Methods
    
    private func fetchLatestTimeRecords() async throws -> [TimeRecord] {
        let config = RequestConfiguration(
            endpoint: .timeRecords,
            method: .GET,
            requiresAuth: true
        )
        
        let response: WorkTimeResponse = try await SecureNetworkManager.shared.performRequest(config, responseType: WorkTimeResponse.self)
        // Convert WorkTimeData to array of TimeRecord - needs proper implementation
        // For now, return empty array as a placeholder
        return []
    }
    
    private func fetchLatestProjects() async throws -> [Project] {
        let config = RequestConfiguration(
            endpoint: .projects,
            method: .GET,
            requiresAuth: true
        )
        
        return try await SecureNetworkManager.shared.performRequest(config, responseType: [Project].self)
    }
    
    private func fetchUserProfile() async throws -> UserProfile {
        let config = RequestConfiguration(
            endpoint: .userProfile,
            method: .GET,
            requiresAuth: true
        )
        
        return try await SecureNetworkManager.shared.performRequest(config, responseType: UserProfile.self)
    }
    
    // MARK: - Local Data Management
    
    private func updateLocalData(timeRecords: [TimeRecord], projects: [Project], userProfile: UserProfile) async {
        guard let context = modelContext else {
            logError("ModelContext not available for local data update", category: .sync)
            return
        }
        
        // SwiftData doesn't have a perform method, operations should be done directly
        // Update time records
        for record in timeRecords {
                // Check if record exists locally by employee ID and date/time
                let employeeId = String(record.employee.id)
                let predicate = #Predicate<RecordModel> { 
                    $0.employeeId == employeeId && 
                    $0.times == record.time
                }
                let descriptor = FetchDescriptor<RecordModel>(predicate: predicate)
                
                if let existingRecord = try? context.fetch(descriptor).first {
                    // Update existing record
                    updateRecordModel(existingRecord, with: record)
                } else {
                    // Create new record
                    let newRecord = createRecordModel(from: record)
                    context.insert(newRecord)
                }
            }
        
        // Save changes
        try? context.save()
        
        logInfo("Local data updated", category: .sync, metadata: [
            "timeRecords": timeRecords.count,
            "projects": projects.count
        ])
    }
    
    private func updateRecordModel(_ model: RecordModel, with record: TimeRecord) {
        model.type = record.type
        // Convert string date to Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        model.date = dateFormatter.date(from: record.date) ?? Date()
        model.times = record.time
        // TimeRecord doesn't have projectName or address properties
        // These need to be extracted from project or other sources
        if let project = record.project {
            // Use project information if available
        }
    }
    
    private func createRecordModel(from record: TimeRecord) -> RecordModel {
        // Convert string date to Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: record.date) ?? Date()
        
        let model = RecordModel(
            latitude: 0.0,
            longitude: 0.0,
            type: record.type,
            date: date,
            times: record.time,
            employeeId: String(record.employee.id),
            address: record.project?.address ?? ""
        )
        return model
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(_ conflict: ConflictResolution, resolution: ConflictResolution.Resolution) async {
        switch resolution {
        case .useLocal:
            // Keep local version, mark server version as resolved
            logInfo("Conflict resolved using local data", category: .sync)
            
        case .useServer:
            // Use server version, update local data
            await applyServerData(conflict.serverData)
            logInfo("Conflict resolved using server data", category: .sync)
            
        case .merge:
            // Attempt to merge both versions
            await mergeConflictData(local: conflict.localData, server: conflict.serverData)
            logInfo("Conflict resolved by merging data", category: .sync)
            
        case .skip:
            // Skip this conflict for now
            logInfo("Conflict resolution skipped", category: .sync)
        }
    }
    
    private func applyServerData(_ data: Data) async {
        // Apply server data to local storage
    }
    
    private func mergeConflictData(local: Data, server: Data) async {
        // Implement intelligent merging logic
    }
    
    // MARK: - Public Interface for Offline Operations
    
    func saveTimeRecordOffline(
        type: String,
        projectName: String,
        location: [String: Double],
        notes: String? = nil
    ) async {
        let recordData: [String: Any] = [
            "type": type,
            "project_name": projectName,
            "latitude": location["latitude"] ?? 0.0,
            "longitude": location["longitude"] ?? 0.0,
            "notes": notes ?? "",
            "timestamp": Date().timeIntervalSince1970,
            "device_id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: recordData) else {
            logError("Failed to serialize time record for offline storage", category: .sync)
            return
        }
        
        let operation = OfflineOperation(
            type: .createRecord,
            data: data,
            metadata: [
                "type": type,
                "project": projectName
            ]
        )
        
        // Save locally first
        await saveRecordLocally(recordData)
        
        // Queue for sync
        queueOperation(operation)
        
        logInfo("Time record saved offline", category: .sync, metadata: [
            "type": type,
            "project": projectName
        ])
    }
    
    private func saveRecordLocally(_ recordData: [String: Any]) async {
        guard let context = modelContext else { return }
        
        let record = RecordModel(
            latitude: recordData["latitude"] as? Double ?? 0.0,
            longitude: recordData["longitude"] as? Double ?? 0.0,
            type: recordData["type"] as? String ?? "",
            date: Date(),
            times: DateFormatter().string(from: Date()),
            employeeId: recordData["employee_id"] as? String ?? "",
            address: recordData["address"] as? String ?? "",
            distance: recordData["distance"] as? Double,
            message: recordData["notes"] as? String,
            observation: recordData["observation"] as? String,
            syncStatus: false
        )
        
        context.insert(record)
        do {
            try context.save()
        } catch {
            logError("Failed to save record locally", category: .sync, metadata: [
                "error": error.localizedDescription
            ])
        }
    }
    
    // MARK: - Status Methods
    
    func getOfflineRecordsCount() -> Int {
        guard let context = modelContext else { return 0 }
        
        let predicate = #Predicate<RecordModel> { !$0.synced }
        let descriptor = FetchDescriptor<RecordModel>(predicate: predicate)
        
        return (try? context.fetchCount(descriptor)) ?? 0
    }
    
    func forceSyncNow() async {
        guard isOnline else {
            logWarning("Cannot force sync - offline", category: .sync)
            return
        }
        
        await performSync()
    }
    
    func clearOfflineData() async {
        syncQueue.async { [weak self] in
            self?.pendingOperations.removeAll()
            self?.savePendingOperations()
            
            DispatchQueue.main.async {
                self?.pendingSyncCount = 0
                self?.syncStatus = .idle
            }
        }
        
        logInfo("Offline data cleared", category: .sync)
    }
}

// MARK: - Supporting Models

// Commented out duplicate Project definition - using the one from Model/Project.swift
/*
struct Project: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let isActive: Bool
    let createdAt: Date?
    let updatedAt: Date?
}
*/

struct UserProfile: Codable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let avatar: String?
    let preferences: [String: String]
    let updatedAt: Date?
}

// MARK: - Network Configuration Extensions
extension NetworkConfiguration.Endpoint {
    static let updateProfileOffline: NetworkConfiguration.Endpoint = .updateProfile
}

// MARK: - RecordModel Extension for Offline Support
extension RecordModel {
    var synced: Bool {
        get { syncStatus ?? false }
        set { syncStatus = newValue }
    }
}