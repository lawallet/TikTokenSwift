import Foundation

struct FileDecoder {
    func decode(_ data: Data) throws -> BpeRanks {
        var parseKey = true
        var lineKey:[CChar] = []
        var lineRank:[CChar] = []
        var result: BpeRanks = [:]
        for sub in data {
            // Have we hit the space in the line?
            if (sub == 32) {
                // Append end of string character so that we can initialize this as a string to base64 decode it
                lineKey.append(0)
                parseKey = false
            } else if (sub == 10) { // Have we hit a new line?
                parseKey = true
                // Bits are bits Apple, why must you force me to create a string to decode base64?
                let encodeString = String(cString: lineKey)
                guard let decodedData = Data(base64Encoded: encodeString) else {
                    throw TikTokenError.bpeParse
                }
                var decodedCharArr: [UInt8] = []
                for dat in decodedData {
                    decodedCharArr.append(dat)
                }
                // Calling C sucks in swift, maybe just use Int using string initializer
                // Use strtol to convert character to string
                var out = UnsafeMutablePointer<CChar>(nil)
                let rank = strtol(lineRank, &out, 10)
                result[decodedCharArr] = rank
                lineKey = []
                lineRank = []
            } else {
                if parseKey {
                    lineKey.append(CChar(sub))
                } else {
                    lineRank.append(CChar(sub))
                }
            }
        }
        return result
    }
}
