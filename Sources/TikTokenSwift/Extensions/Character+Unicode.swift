import Foundation

extension Character {
    init?(unicodeValue: Int) {
        guard let unicodeScalar = Unicode.Scalar(unicodeValue) else {
            return nil
        }
        self.init(unicodeScalar)
    }
}
