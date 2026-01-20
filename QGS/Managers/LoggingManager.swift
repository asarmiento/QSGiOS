import Foundation
import os.log

// MARK: - Log Level
enum LogLevel: String, CaseIterable {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
    
    var priority: Int {
        switch self {
        case .verbose: return 0
        case .debug: return 1
        case .info: return 2
        case .warning: return 3
        case .error: return 4
        case .critical: return 5
        }
    }
}

// MARK: - Log Category
enum LogCategory: String, CaseIterable {
    case general = "General"
    case network = "Network"
    case database = "Database"
    case authentication = "Authentication"
    case location = "Location"
    case ui = "UI"
    case performance = "Performance"
    case security = "Security"
    case push = "Push"
    case sync = "Sync"
    
    var subsystem: String {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.qgs.app"
        return "\(bundleId).logging"
    }
    
    var osLog: OSLog {
        OSLog(subsystem: subsystem, category: self.rawValue)
    }
}

// MARK: - Log Entry
struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let file: String
    let function: String
    let line: Int
    let metadata: [String: Any]?
    
    var formattedMessage: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestampString = formatter.string(from: timestamp)
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let location = "[\(fileName):\(line)] \(function)"
        
        var message = "[\(timestampString)] [\(level.rawValue)] [\(category.rawValue)] \(location): \(self.message)"
        
        if let metadata = metadata, !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            message += " | Metadata: {\(metadataString)}"
        }
        
        return message
    }
}

// MARK: - Log Destination Protocol
protocol LogDestination {
    func write(_ entry: LogEntry)
    func flush()
}

// MARK: - Console Log Destination
class ConsoleLogDestination: LogDestination {
    private let minimumLevel: LogLevel
    
    init(minimumLevel: LogLevel = .debug) {
        self.minimumLevel = minimumLevel
    }
    
    func write(_ entry: LogEntry) {
        guard entry.level.priority >= minimumLevel.priority else { return }
        
        os_log("%{public}@", log: entry.category.osLog, type: entry.level.osLogType, entry.formattedMessage)
        
        // Also print to console in debug mode
        if AppConfigurationManager.shared.isDebugMode {
            print(entry.formattedMessage)
        }
    }
    
    func flush() {
        // Console logs are immediately flushed
    }
}

// MARK: - File Log Destination
class FileLogDestination: LogDestination {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "FileLogDestination", qos: .utility)
    private let fileManager = FileManager.default
    private let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    private let maxFiles: Int = 5
    
    init() throws {
        let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let logsDirectory = documentsURL.appendingPathComponent("Logs")
        
        if !fileManager.fileExists(atPath: logsDirectory.path) {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        }
        
        let appName = AppConfigurationManager.shared.current.appName.replacingOccurrences(of: " ", with: "_")
        self.fileURL = logsDirectory.appendingPathComponent("\(appName)_\(Date().timeIntervalSince1970).log")
    }
    
    func write(_ entry: LogEntry) {
        queue.async { [weak self] in
            self?.writeToFile(entry)
        }
    }
    
    private func writeToFile(_ entry: LogEntry) {
        let logLine = entry.formattedMessage + "\n"
        guard let data = logLine.data(using: .utf8) else { return }
        
        if fileManager.fileExists(atPath: fileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                
                // Check file size and rotate if needed
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? Int64,
                   fileSize > maxFileSize {
                    rotateLogFiles()
                }
            }
        } else {
            try? data.write(to: fileURL)
        }
    }
    
    private func rotateLogFiles() {
        let logsDirectory = fileURL.deletingLastPathComponent()
        guard let logFiles = try? fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles]) else { return }
        
        let sortedFiles = logFiles.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
        
        // Keep only the latest files
        if sortedFiles.count >= maxFiles {
            let filesToDelete = sortedFiles.suffix(from: maxFiles - 1)
            for file in filesToDelete {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    func flush() {
        queue.sync {
            // File operations are synchronous, so nothing to flush
        }
    }
}

// MARK: - Remote Log Destination
class RemoteLogDestination: LogDestination {
    private let queue = DispatchQueue(label: "RemoteLogDestination", qos: .utility)
    private var logBuffer: [LogEntry] = []
    private let bufferSize = 50
    private let uploadInterval: TimeInterval = 300 // 5 minutes
    private var uploadTimer: Timer?
    
    init() {
        startUploadTimer()
    }
    
    func write(_ entry: LogEntry) {
        queue.async { [weak self] in
            self?.logBuffer.append(entry)
            
            if self?.logBuffer.count ?? 0 >= self?.bufferSize ?? 0 {
                self?.uploadLogs()
            }
        }
    }
    
    private func startUploadTimer() {
        uploadTimer = Timer.scheduledTimer(withTimeInterval: uploadInterval, repeats: true) { [weak self] _ in
            self?.uploadLogs()
        }
    }
    
    private func uploadLogs() {
        guard !logBuffer.isEmpty else { return }
        
        let logsToUpload = logBuffer
        logBuffer.removeAll()
        
        // TODO: Implement actual remote logging service
        // This could be Firebase Analytics, Crashlytics, or custom service
        print("Uploading \(logsToUpload.count) logs to remote service...")
    }
    
    func flush() {
        queue.sync {
            uploadLogs()
        }
    }
    
    deinit {
        uploadTimer?.invalidate()
        flush()
    }
}

// MARK: - Logging Manager
class LoggingManager {
    static let shared = LoggingManager()
    
    private var destinations: [LogDestination] = []
    private let queue = DispatchQueue(label: "LoggingManager", qos: .utility)
    
    private init() {
        setupDestinations()
    }
    
    private func setupDestinations() {
        // Console logging (always enabled)
        destinations.append(ConsoleLogDestination())
        
        // File logging (enabled in debug and production)
        if let fileDestination = try? FileLogDestination() {
            destinations.append(fileDestination)
        }
        
        // Remote logging (only in production)
        if AppConfigurationManager.shared.isProduction {
            destinations.append(RemoteLogDestination())
        }
    }
    
    func log(
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [String: Any]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line,
            metadata: metadata
        )
        
        queue.async { [weak self] in
            self?.destinations.forEach { $0.write(entry) }
        }
    }
    
    func flush() {
        queue.sync {
            destinations.forEach { $0.flush() }
        }
    }
}

// MARK: - Convenience Extensions
extension LoggingManager {
    func verbose(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .verbose, category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .critical, category: category, message: message, metadata: metadata, file: file, function: function, line: line)
    }
}

// MARK: - Global Logging Functions
func logVerbose(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingManager.shared.verbose(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

func logDebug(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingManager.shared.debug(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingManager.shared.info(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingManager.shared.warning(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

func logError(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingManager.shared.error(message, category: category, metadata: metadata, file: file, function: function, line: line)
}

func logCritical(_ message: String, category: LogCategory = .general, metadata: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    LoggingManager.shared.critical(message, category: category, metadata: metadata, file: file, function: function, line: line)
}