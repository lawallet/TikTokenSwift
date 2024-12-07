import Foundation

public enum TikTokenError: LocalizedError {
    case invalidEncoderParams
    case invalidVocabParams
    case bpeCountMismatch(Int, Int)
    case bpeParse
    case general
    case file
    case validation
    case disallowedToken(String)
    case unicode
    
    public var errorDescription: String? {
        switch self {
            
        case .invalidEncoderParams:
            "Invalid parameter for json encoder"
        case .invalidVocabParams:
            "Invalid parameter for bpe file"
        case .bpeCountMismatch:
            "Count of BPE value do not match"
        case .bpeParse:
            "Parsing of BPE error failed"
        case .general:
            "Can not create BPE"
        case .file:
            "Error saving BPE file to storage"
        case .validation:
            "Validation failed"
        case .disallowedToken:
            "Disallowed token"
        case .unicode:
            "Unable to parse unicode"
        }
    }
    
    public var failureReason: String? {
        switch self {
            
        case .invalidEncoderParams:
            "The url provided for the BPE is not a valid url"
        case .invalidVocabParams:
            "The url provided for the BPE encoder is not a valid url"
        case .bpeCountMismatch(let expected, let gotten):
            "The count of provided bpe (\(gotten)) does not match expected value (\(expected))"
        case .bpeParse:
            "Unable to parse string provided"
        case .general:
            "A problem occured"
        case .file:
            "A problem occurred when trying to read file from disk"
        case .validation:
            "The built bpe merge does not the number expected"
        case .disallowedToken(let disallowedToken):
            "Special token \(disallowedToken) was found in text"
        case .unicode:
            "Parser was unable to parse unicode value"
        }
    }
}
