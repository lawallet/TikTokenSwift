import Foundation

public class Encoding {    
    private let name: String
    private let regex: NSRegularExpression // Regex
    private let mergedRanks: BpeRanks
    private let specialTokens: [String: Int]
    private let explicitNVocab: Int?
    
    private let coreBpe: CoreBPE
    
    init(name: String, regex: NSRegularExpression, mergedRanks: BpeRanks, specialTokens: [String: Int], explicitNVocab: Int? = nil) throws {
        self.name = name
        self.regex = regex
        self.mergedRanks = mergedRanks
        self.specialTokens = specialTokens
  
        // Make sure the bpe list count matches vocab value
        self.explicitNVocab = explicitNVocab
        if let explicitVocabCount = explicitNVocab {
            let totalVocab = mergedRanks.keys.count
            if totalVocab != explicitVocabCount {
                throw TikTokenError.bpeCountMismatch(explicitVocabCount, totalVocab)
            }
        }
        
        let decoder = mergedRanks.keyValueSwapped
        self.coreBpe = .init(encoder: mergedRanks, decoder: decoder, regexTls: [regex])
    }
    
    public func encode(value: String, treatSpecialAsNormal: Bool = false) throws -> [Int] {
        if (treatSpecialAsNormal == false) {
            for specialToken in specialTokens.keys {
                if (value.contains(specialToken)) {
                    throw TikTokenError.disallowedToken(specialToken)
                }
            }
        }
        
        return try coreBpe.encodeOrdinaryNative(text: value.convertFromPythonHexCodeToUnicodeCode().convertFromUnicodeString() ?? value)
    }
    
    public func decode(value: [Int]) -> String {
        coreBpe.decodeNative(tokens: value)
    }
}
