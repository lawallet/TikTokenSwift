import Foundation

struct Model {
    static func getEncoding(_ model: GptModel) -> Vocab {
        return model.modelForEncoder
    }
}

public enum GptModel: String {
    case gpt4o = "gpt-4o"
    case gpt4 = "gpt-4"
    case gpt35Turbo = "gpt-3.5-turbo"
    
    case textdavinci003 = "text-davinci-003"
    case textdavinci002 = "text-davinci-002"
    case textdavinci001 = "text-davinci-001"
    case textcurie001 = "text-curie-001"
    case textbabbage001 = "text-babbage-001"
    case textada001 = "text-ada-001"
    case davinci = "davinci"
    case curie = "curie"
    case babbage = "babbage"
    case ada = "ada"
    
    case codedavinci002 = "code-davinci-002"
    case codedavinci001 = "code-davinci-001"
    case codecushman002 = "code-cushman-002"
    case codecushman001 = "code-cushman-001"
    case davincicodex = "davinci-codex"
    case cushmancodex = "cushman-codex"
    
    case textdavinciedit001 = "text-davinci-edit-001"
    case codedavinciedit001 = "code-davinci-edit-001"
    
    case textembeddingada002 = "text-embedding-ada-002"
    
    case textsimilaritydavinci001 = "text-similarity-davinci-001"
    case textsimilaritycurie001 = "text-similarity-curie-001"
    case textsimilaritybabbage001 = "text-similarity-babbage-001"
    case textsimilarityada001 = "text-similarity-ada-001"
    case textsearchdavincidoc001 = "text-search-davinci-doc-001"
    case textsearchcuriedoc001 = "text-search-curie-doc-001"
    case textsearchbabbagedoc001 = "text-search-babbage-doc-001"
    case textsearchadadoc001 = "text-search-ada-doc-001"
    case codesearchbabbagecode001 = "code-search-babbage-code-001"
    case codesearchadacode001 = "code-search-ada-code-001"
    
    case gpt2 = "gpt2"
    
    var modelForEncoder: Vocab {
        switch self {
        case .gpt4o:
            return .o200kBase
        case .gpt4, .gpt35Turbo, .textembeddingada002:
            return .cl100kBase
        case .textdavinci003, .textdavinci002, .codedavinci002, .codedavinci001, .codecushman002, .codecushman001, .davincicodex, .cushmancodex:
            return .p50kBase
        case .textdavinci001, .textcurie001, .textbabbage001, .textada001, .davinci, .curie, .babbage, .ada, .textsimilaritydavinci001, .textsimilaritycurie001, .textsimilaritybabbage001, .textsimilarityada001, .textsearchdavincidoc001, .textsearchcuriedoc001, .textsearchbabbagedoc001, .textsearchadadoc001, .codesearchadacode001, .codesearchbabbagecode001:
            return .r50kBase
        case .textdavinciedit001, .codedavinciedit001:
            return .p50kEdit
        case .gpt2:
            return .gpt2
        }
    }
}
