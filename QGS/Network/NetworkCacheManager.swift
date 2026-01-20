import Foundation

// MARK: - Network Cache Manager
/// Intelligent caching system for network requests to improve performance and reduce API calls
class NetworkCacheManager {
    static let shared = NetworkCacheManager()
    
    private let cache = NSCache<NSString, CachedResponse>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let defaultTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {
        // Setup memory cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Setup disk cache directory
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NetworkCache")
        
        createCacheDirectoryIfNeeded()
        
        logInfo("NetworkCacheManager initialized", category: .network)
    }
    
    // MARK: - Cache Operations
    
    /// Store a response in cache with custom timeout
    func store<T: Codable>(_ response: T, for key: String, timeout: TimeInterval? = nil) {
        let cacheTimeout = timeout ?? defaultTimeout
        let cachedResponse = CachedResponse(data: response, timeout: cacheTimeout)
        
        // Store in memory cache
        cache.setObject(cachedResponse, forKey: key as NSString)
        
        // Store in disk cache for persistence
        storeToDisk(cachedResponse, for: key)
        
        logDebug("Response cached", category: .network, metadata: [
            "key": key,
            "timeout": cacheTimeout
        ])
    }
    
    /// Retrieve a cached response
    func retrieve<T: Codable>(_ type: T.Type, for key: String) -> T? {
        // Check memory cache first
        if let cachedResponse = cache.object(forKey: key as NSString),
           cachedResponse.isValid {
            logDebug("Cache hit (memory)", category: .network, metadata: ["key": key])
            return cachedResponse.data as? T
        }
        
        // Check disk cache
        if let cachedResponse = retrieveFromDisk(key),
           cachedResponse.isValid {
            // Move back to memory cache
            cache.setObject(cachedResponse, forKey: key as NSString)
            logDebug("Cache hit (disk)", category: .network, metadata: ["key": key])
            return cachedResponse.data as? T
        }
        
        logDebug("Cache miss", category: .network, metadata: ["key": key])
        return nil
    }
    
    /// Check if a cache entry exists and is valid
    func isValid(for key: String) -> Bool {
        if let cachedResponse = cache.object(forKey: key as NSString) {
            return cachedResponse.isValid
        }
        
        if let cachedResponse = retrieveFromDisk(key) {
            return cachedResponse.isValid
        }
        
        return false
    }
    
    /// Remove a specific cache entry
    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
        removeFromDisk(key)
        
        logDebug("Cache entry removed", category: .network, metadata: ["key": key])
    }
    
    /// Clear all cache entries
    func clearAll() {
        cache.removeAllObjects()
        clearDiskCache()
        
        logInfo("All cache cleared", category: .network)
    }
    
    /// Clear expired cache entries
    func clearExpired() {
        let allKeys = getAllDiskCacheKeys()
        var removedCount = 0
        
        for key in allKeys {
            if let cachedResponse = retrieveFromDisk(key),
               !cachedResponse.isValid {
                removeFromDisk(key)
                cache.removeObject(forKey: key as NSString)
                removedCount += 1
            }
        }
        
        logInfo("Expired cache entries cleared", category: .network, metadata: [
            "removedCount": removedCount
        ])
    }
    
    // MARK: - Disk Cache Operations
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func storeToDisk(_ cachedResponse: CachedResponse, for key: String) {
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try JSONEncoder().encode(cachedResponse)
            try data.write(to: fileURL)
        } catch {
            logError("Failed to store cache to disk", category: .network, metadata: [
                "key": key,
                "error": error.localizedDescription
            ])
        }
    }
    
    private func retrieveFromDisk(_ key: String) -> CachedResponse? {
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(CachedResponse.self, from: data)
        } catch {
            logError("Failed to retrieve cache from disk", category: .network, metadata: [
                "key": key,
                "error": error.localizedDescription
            ])
            // Remove corrupted cache file
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    private func removeFromDisk(_ key: String) {
        let fileName = sanitizeFileName(key)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        try? fileManager.removeItem(at: fileURL)
    }
    
    private func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
    
    private func getAllDiskCacheKeys() -> [String] {
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: cacheDirectory.path)
            return fileNames.map { $0.replacingOccurrences(of: ".cache", with: "") }
        } catch {
            return []
        }
    }
    
    private func sanitizeFileName(_ key: String) -> String {
        let sanitized = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
        return "\(sanitized).cache"
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() -> CacheStatistics {
        let memoryCount = cache.countLimit
        let diskCount = getAllDiskCacheKeys().count
        let memorySize = cache.totalCostLimit
        
        return CacheStatistics(
            memoryEntries: memoryCount,
            diskEntries: diskCount,
            memorySize: memorySize,
            diskSize: getDiskCacheSize()
        )
    }
    
    private func getDiskCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            for fileURL in fileURLs {
                let fileAttributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = fileAttributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        } catch {
            logError("Failed to calculate disk cache size", category: .network, metadata: [
                "error": error.localizedDescription
            ])
        }
        
        return totalSize
    }
}

// MARK: - Supporting Types

/// Cached response wrapper with expiration
class CachedResponse: NSObject, Codable {
    let data: Data
    private let timestamp: Date
    private let timeout: TimeInterval
    
    init<T: Codable>(data: T, timeout: TimeInterval) {
        do {
            self.data = try JSONEncoder().encode(data)
        } catch {
            logError("Failed to encode data for caching", category: .network)
            self.data = Data()
        }
        self.timestamp = Date()
        self.timeout = timeout
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(Data.self, forKey: .data)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        timeout = try container.decode(TimeInterval.self, forKey: .timeout)
        super.init()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(timeout, forKey: .timeout)
    }
    
    /// Check if the cached response is still valid
    var isValid: Bool {
        Date().timeIntervalSince(timestamp) < timeout
    }
    
    /// Get the age of the cached response
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
    
    private enum CodingKeys: String, CodingKey {
        case data, timestamp, timeout
    }
}

/// Cache statistics for monitoring
struct CacheStatistics {
    let memoryEntries: Int
    let diskEntries: Int
    let memorySize: Int
    let diskSize: Int64
    
    var formattedMemorySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(memorySize), countStyle: .memory)
    }
    
    var formattedDiskSize: String {
        ByteCountFormatter.string(fromByteCount: diskSize, countStyle: .file)
    }
}

// MARK: - Cache Key Generation
extension NetworkCacheManager {
    /// Generate cache key for time records
    static func timeRecordsCacheKey(employeeId: String? = nil, date: Date? = nil) -> String {
        var key = "timeRecords"
        if let employeeId = employeeId {
            key += "_\(employeeId)"
        }
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            key += "_\(formatter.string(from: date))"
        }
        return key
    }
    
    /// Generate cache key for employee list
    static func employeeListCacheKey() -> String {
        return "employeeList"
    }
    
    /// Generate cache key for projects
    static func projectsCacheKey() -> String {
        return "projects"
    }
    
    /// Generate cache key for user profile
    static func userProfileCacheKey(userId: String) -> String {
        return "userProfile_\(userId)"
    }
}

// MARK: - Extension for Common Use Cases
extension NetworkCacheManager {
    /// Convenience method for caching time records with appropriate timeout
    func cacheTimeRecords(_ records: [TimeRecord], employeeId: String? = nil, date: Date? = nil) {
        let key = NetworkCacheManager.timeRecordsCacheKey(employeeId: employeeId, date: date)
        store(records, for: key, timeout: 300) // 5 minutes for time records
    }
    
    /// Convenience method for retrieving cached time records
    func getCachedTimeRecords(employeeId: String? = nil, date: Date? = nil) -> [TimeRecord]? {
        let key = NetworkCacheManager.timeRecordsCacheKey(employeeId: employeeId, date: date)
        return retrieve([TimeRecord].self, for: key)
    }
    
    /// Convenience method for caching employee list with longer timeout
    func cacheEmployeeList(_ employees: [Employee]) {
        let key = NetworkCacheManager.employeeListCacheKey()
        store(employees, for: key, timeout: 1800) // 30 minutes for employee list
    }
    
    /// Convenience method for retrieving cached employee list
    func getCachedEmployeeList() -> [Employee]? {
        let key = NetworkCacheManager.employeeListCacheKey()
        return retrieve([Employee].self, for: key)
    }
}