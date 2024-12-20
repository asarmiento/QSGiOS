import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var error: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
} 