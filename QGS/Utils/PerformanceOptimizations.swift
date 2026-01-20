import SwiftUI
import Combine
import UIKit

// MARK: - Performance Optimizations for SwiftUI

/// Optimized ViewModel base class that reduces unnecessary updates
class OptimizedViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let updateQueue = DispatchQueue(label: "viewmodel.updates", qos: .userInitiated)
    
    /// Debounced update mechanism to prevent too frequent UI updates
    private let debounceSubject = PassthroughSubject<Void, Never>()
    
    init() {
        setupDebouncedUpdates()
    }
    
    private func setupDebouncedUpdates() {
        debounceSubject
            .debounce(for: .milliseconds(16), scheduler: DispatchQueue.main) // 60fps limit
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Trigger an optimized update (debounced)
    func triggerOptimizedUpdate() {
        debounceSubject.send()
    }
    
    /// Force immediate update (use sparingly)
    func triggerImmediateUpdate() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Optimized Button State Management

/// Consolidated button state to reduce multiple @State variables
struct ButtonState: Equatable {
    var isLoading = false
    var isEnabled = true
    var showSuccessAlert = false
    var showErrorAlert = false
    var successMessage = ""
    var errorMessage = ""
    
    static func == (lhs: ButtonState, rhs: ButtonState) -> Bool {
        lhs.isLoading == rhs.isLoading &&
        lhs.isEnabled == rhs.isEnabled &&
        lhs.showSuccessAlert == rhs.showSuccessAlert &&
        lhs.showErrorAlert == rhs.showErrorAlert &&
        lhs.successMessage == rhs.successMessage &&
        lhs.errorMessage == rhs.errorMessage
    }
}

// MARK: - Optimized Record Button Component

/// High-performance button component that minimizes re-renders
struct OptimizedRecordButton: View {
    let type: RecordType
    let action: () -> Void
    
    @Binding var buttonState: ButtonState
    @Environment(\.colorScheme) var colorScheme
    
    // Use computed properties to minimize state
    private var backgroundColor: Color {
        switch type {
        case .entrada:
            return buttonState.isEnabled ? .green : .gray
        case .salida:
            return buttonState.isEnabled ? .red : .gray
        }
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if buttonState.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(textColor)
                } else {
                    Image(systemName: type.iconName)
                        .foregroundColor(textColor)
                }
                
                Text(type.title)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .disabled(!buttonState.isEnabled || buttonState.isLoading)
        .animation(.easeInOut(duration: 0.2), value: buttonState.isEnabled)
        .animation(.easeInOut(duration: 0.2), value: buttonState.isLoading)
    }
}

enum RecordType {
    case entrada
    case salida
    
    var title: String {
        switch self {
        case .entrada: return "Entrada"
        case .salida: return "Salida"
        }
    }
    
    var iconName: String {
        switch self {
        case .entrada: return "clock.arrow.circlepath"
        case .salida: return "clock.badge.checkmark"
        }
    }
}

// MARK: - Optimized List Components

/// High-performance list row that uses equatable for diffing
struct OptimizedTimeRecordRow: View, Equatable {
    let record: TimeRecord
    let onTap: ((TimeRecord) -> Void)?
    
    static func == (lhs: OptimizedTimeRecordRow, rhs: OptimizedTimeRecordRow) -> Bool {
        lhs.record.id == rhs.record.id &&
        lhs.record.date == rhs.record.date &&
        lhs.record.type == rhs.record.type
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.project?.name ?? "Unknown Project")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(formatDate(record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.type == "e" ? "Entrada" : "Salida")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(record.type == "e" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(4)
                
                Text(record.time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?(record)
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Cache date formatter for performance
        struct DateFormatterCache {
            static let shared = DateFormatter()
        }
        
        let formatter = DateFormatterCache.shared
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Optimized Search Bar

/// Debounced search bar to prevent excessive filtering
struct OptimizedSearchBar: View {
    @Binding var searchText: String
    let onSearchChanged: (String) -> Void
    
    @State private var internalSearchText = ""
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Buscar...", text: $internalSearchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onReceive(
                    Just(internalSearchText)
                        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                ) { value in
                    searchText = value
                    onSearchChanged(value)
                }
            
            if !internalSearchText.isEmpty {
                Button("Limpiar") {
                    internalSearchText = ""
                    searchText = ""
                    onSearchChanged("")
                }
                .foregroundColor(.secondary)
            }
        }
        .onAppear {
            internalSearchText = searchText
        }
    }
}

// MARK: - Memory Management Helpers

/// Weak reference wrapper for closures to prevent retain cycles
class WeakWrapper<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}

/// Memory-efficient image loading with automatic cleanup
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var cancellable: AnyCancellable?
    private static let cache = NSCache<NSString, UIImage>()
    
    func load(from url: URL) {
        let cacheKey = url.absoluteString as NSString
        
        // Check cache first
        if let cachedImage = Self.cache.object(forKey: cacheKey) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loadedImage in
                self?.isLoading = false
                self?.image = loadedImage
                
                if let loadedImage = loadedImage {
                    Self.cache.setObject(loadedImage, forKey: cacheKey)
                }
            }
    }
    
    deinit {
        cancellable?.cancel()
    }
}

// MARK: - Performance Monitoring

/// Simple performance monitor for debugging
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var startTimes: [String: Date] = [:]
    
    func startMeasuring(_ identifier: String) {
        startTimes[identifier] = Date()
    }
    
    func endMeasuring(_ identifier: String) -> TimeInterval? {
        guard let startTime = startTimes[identifier] else { return nil }
        let duration = Date().timeIntervalSince(startTime)
        startTimes.removeValue(forKey: identifier)
        
        logDebug("Performance measurement", category: .performance, metadata: [
            "identifier": identifier,
            "duration": "\(duration * 1000)ms"
        ])
        
        return duration
    }
}

// MARK: - View Extensions for Performance

extension View {
    /// Add performance monitoring to any view
    func measurePerformance(_ identifier: String) -> some View {
        self.onAppear {
            PerformanceMonitor.shared.startMeasuring("\(identifier)_appear")
        }
        .onDisappear {
            let _ = PerformanceMonitor.shared.endMeasuring("\(identifier)_appear")
        }
    }
    
    /// Conditionally apply a modifier for performance
    @ViewBuilder
    func conditionalModifier<M: ViewModifier>(_ condition: Bool, modifier: M) -> some View {
        if condition {
            self.modifier(modifier)
        } else {
            self
        }
    }
    
    /// Apply smart keyboard dismissal
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    /// Smart keyboard avoidance
    func smartKeyboardAvoidance() -> some View {
        self.ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Optimized ViewModels

/// Optimized TimeRecords ViewModel with caching and pagination
class OptimizedTimeRecordsViewModel: OptimizedViewModel {
    @Published var timeRecords: [TimeRecord] = []
    @Published var filteredRecords: [TimeRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoadingMore = false
    
    private var currentPage = 0
    private let pageSize = 50
    private var hasMoreData = true
    private let cacheManager = NetworkCacheManager.shared
    
    /// Load time records with intelligent caching
    func loadTimeRecords(refresh: Bool = false) async {
        if refresh {
            currentPage = 0
            hasMoreData = true
            await MainActor.run {
                timeRecords.removeAll()
                filteredRecords.removeAll()
            }
        }
        
        // Check cache first (if not refreshing)
        if !refresh, let cachedRecords = cacheManager.getCachedTimeRecords() {
            await MainActor.run {
                self.timeRecords = cachedRecords
                self.filteredRecords = cachedRecords
                self.isLoading = false
            }
            return
        }
        
        guard hasMoreData else { return }
        
        await MainActor.run {
            if refresh {
                isLoading = true
            } else {
                isLoadingMore = true
            }
        }
        
        do {
            // Simulate API call with pagination
            let newRecords = try await fetchTimeRecordsPage(page: currentPage, limit: pageSize)
            
            await MainActor.run {
                if refresh {
                    self.timeRecords = newRecords
                } else {
                    self.timeRecords.append(contentsOf: newRecords)
                }
                
                self.filteredRecords = self.timeRecords
                self.hasMoreData = newRecords.count == self.pageSize
                self.currentPage += 1
                self.isLoading = false
                self.isLoadingMore = false
                
                // Cache the results
                self.cacheManager.cacheTimeRecords(self.timeRecords)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.isLoadingMore = false
            }
        }
    }
    
    /// Filter records efficiently
    func filterRecords(searchText: String) {
        if searchText.isEmpty {
            filteredRecords = timeRecords
        } else {
            filteredRecords = timeRecords.filter { record in
                record.project?.name.localizedCaseInsensitiveContains(searchText) == true ||
                record.project?.address?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        triggerOptimizedUpdate()
    }
    
    private func fetchTimeRecordsPage(page: Int, limit: Int) async throws -> [TimeRecord] {
        // Implementation would call your actual API
        // This is a placeholder
        return []
    }
}