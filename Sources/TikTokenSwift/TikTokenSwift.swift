import Foundation

public struct TikTokenSwift {
    public static let shared: TikTokenSwift = TikTokenSwift()
    
    public func getEncoding(model: GptModel) async throws -> Encoding {
        let vocab = model.modelForEncoder
        let encoder = try await loadRanks(vocab)
        let regex = try NSRegularExpression(pattern: vocab.pattern)
        let encoding = try Encoding(name: model.rawValue, regex: regex, mergedRanks: encoder, specialTokens: vocab.specialTokens, explicitNVocab: vocab.explicitNVocab)
        return encoding
    }
}

private extension TikTokenSwift {
    func loadRanks(_ vocab: Vocab) async throws -> BpeRanks {
        if vocab.name == "gpt2" {
            return try await Load.dataGymToMergeableBpeRanks(vocab: vocab)
        } else {
            return try await Load.loadTiktokenBpe(vocab: vocab)
        }
    }
}
