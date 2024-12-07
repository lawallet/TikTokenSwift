import Foundation

// Essentially a dictionary with a C style string as the key and its corresponding ranking as the value
typealias BpeRanks = [[UInt8]: Int]

extension BpeRanks {
    var keyValueSwapped: [Int: [UInt8]] {
        reduce(into: [:], { $0[$1.value] = $1.key })
    }
}
