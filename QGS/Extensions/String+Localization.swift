import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        let format = NSLocalizedString(self, tableName: "Localizable", bundle: .main, comment: "")
        return String(format: format, arguments: arguments)
    }
} 