import Foundation

extension Unicode.Scalar {
    var pythonIsPrintable: Bool {
        switch properties.generalCategory {
        case .control, .format: 
            return false
        default: 
            return true
        }
    }
}
