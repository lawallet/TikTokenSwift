import Foundation

class CoreBPE {
    private let encoder: BpeRanks
    private let decoder: [Int: [UInt8]]
    private let regexTls: [NSRegularExpression]
    
    init(encoder: [[UInt8] : Int] = .init(),
         decoder: [Int : [UInt8]] = .init(),
         regexTls: [NSRegularExpression] = .init()) {
        self.encoder = encoder
        self.decoder = decoder
        self.regexTls = regexTls
    }
    
    func encodeOrdinaryNative(text: String) throws -> [Int] {
        let regex = regexTls.first!
        var theTokens: [Int] = []
        for mat in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            if let range = Range(mat.range, in: text) {
                let piece = Array(text[range].utf8)
                if let token = encoder[piece] {
                    theTokens.append(token)
                    continue
                }
                // Parts is really just an array of strings
                let calculatedTokens = try decodeUnmatchedString(piece: piece)
                theTokens.append(contentsOf: calculatedTokens)
            }
        }
        return theTokens
    }
    
    func decodeUnmatchedString(piece: [UInt8]) throws -> [Int] {
        var parts:[[UInt8]] = piece.map({Array([$0])})
        var initialRanksList: [Int] = []
        let invalidVal = Int.max
        for num in 0..<parts.count - 1 {
            initialRanksList.append(encoder[parts[num] + parts[num + 1]] ?? invalidVal)
        }
        var merging = true
        while merging {

            var minIndex = -1
            var minRank = -1
            for num in 0..<parts.count - 1 {
                let currRank = initialRanksList[num]
                if currRank != invalidVal {
                    if minRank == -1 || currRank < minRank {
                        minRank = currRank
                        minIndex = num
                    }
                }
            }
            if minRank == -1 {
                merging = false
                break
            }
            if merging {
                if (minIndex == -1) {
                    throw TikTokenError.bpeParse
                }

                let mergedVal = parts[minIndex] + parts[minIndex + 1]
                parts[minIndex] = mergedVal
                parts.remove(at: minIndex + 1)
                if minIndex != parts.count - 1 {
                    let newRank = encoder[parts[minIndex] + parts[minIndex + 1]] ?? invalidVal
                    initialRanksList[minIndex] = newRank
                    initialRanksList.remove(at: minIndex + 1)
                }
                if minIndex != 0 {
                    let newRank = encoder[parts[minIndex - 1] + parts[minIndex]] ?? invalidVal
                    initialRanksList[minIndex - 1] = newRank
                }
            }

        }
        let tokens = parts.compactMap({encoder[$0]})
        return tokens
    }
    
    func decodeNative(tokens: [Int]) -> String {
        let data = tokens.reduce(into: Data(), {
            if let tokenBytes = decoder[$1] {
                $0.append(contentsOf: tokenBytes)
            }
        })
        return String(data: data, encoding: .utf8) ?? ""
    }
}
