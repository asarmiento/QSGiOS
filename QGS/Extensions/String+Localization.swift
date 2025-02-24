import Foundation

extension String {
    var localized: String {
        let bundle = Bundle.main
        return NSLocalizedString(self, tableName: "Localizable", bundle: bundle, comment: "")
    }
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        let format = NSLocalizedString(self, tableName: "Localizable", bundle: .main, comment: "")
        return String(format: format, arguments: arguments)
    }
} 