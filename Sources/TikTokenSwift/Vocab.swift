import Foundation

enum SpecialTokenConstants: String {
    case ENDOFTEXT = "<|endoftext|>"
    case FIM_PREFIX = "<|fim_prefix|>"
    case FIM_MIDDLE = "<|fim_middle|>"
    case FIM_SUFFIX = "<|fim_suffix|>"
    case ENDOFPROMPT = "<|endofprompt|>"
}

internal struct Vocab {
    public let name: String
    public let remoteUrlString: String
    public let encoderUrlString: String?
    public let explicitNVocab: Int?
    public let pattern: String
    public let specialTokens: [String: Int]
    
    public init(name: String,
                remoteUrlString: String,
                encoderUrlString: String? = nil,
                explicitNVocab: Int? = nil,
                pattern: String,
                specialTokens: [String : Int] = [:]) {
        self.name = name
        self.remoteUrlString = remoteUrlString
        self.encoderUrlString = encoderUrlString
        self.explicitNVocab = explicitNVocab
        self.pattern = pattern
        self.specialTokens = specialTokens
    }
    
    func loadVocabData() async throws -> Data {
        guard let remoteUrl = URL(string: remoteUrlString) else {
            throw TikTokenError.invalidVocabParams
        }
        if let vocabUrl = try getLocalVocabLocation() {
            if #available(iOS 16.0, *) {
                if let fileData = FileManager.default.contents(atPath: vocabUrl.path()) {
                    return fileData
                } else {
                    throw TikTokenError.file
                }
            } else {
                if let fileData = FileManager.default.contents(atPath: vocabUrl.path) {
                    return fileData
                } else {
                    throw TikTokenError.file
                }
            }
        } else {
            let remoteData: (data: Data, response: URLResponse)
            
            remoteData = try await URLSession.shared.asyncData(from: remoteUrl)
            
            let fileName = remoteUrl.lastPathComponent
            try writeFileToSupportDirectory(fileName: fileName, data: remoteData.data)
            return remoteData.data
        }
    }
    
    func loadVocabValidationData() async throws -> Data {
        guard let encoderStr = encoderUrlString, let encoderUrl = URL(string: encoderStr) else {
            throw TikTokenError.invalidEncoderParams
        }
        
        if let vocabEncoderUrl = try getLocalVocabEncoderLocation() {
            if #available(iOS 16.0, *) {
                if let fileData = FileManager.default.contents(atPath: vocabEncoderUrl.path()) {
                    return fileData
                } else {
                    throw TikTokenError.invalidEncoderParams
                }
            } else {
                if let fileData = FileManager.default.contents(atPath: vocabEncoderUrl.path) {
                    return fileData
                } else {
                    throw TikTokenError.invalidEncoderParams
                }
            }
        } else {
            let encoderData: (data: Data, response: URLResponse)
           
            encoderData = try await URLSession.shared.asyncData(from: encoderUrl)
            
            let fileName = encoderUrl.lastPathComponent
            try writeFileToSupportDirectory(fileName: fileName, data: encoderData.data)
            return encoderData.data
        }
    }
    
    func writeFileToSupportDirectory(fileName: String, data: Data) throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        // Should always have at least one value, but just in case
        guard let appSupportDir = appSupport.first else {
            throw TikTokenError.file
        }
        
        let localFilePath: URL
        if #available(iOS 16.0, *) {
            localFilePath = appSupportDir.appending(path: fileName, directoryHint: .notDirectory)
        } else {
            localFilePath = appSupportDir.appendingPathComponent(fileName, isDirectory: false)
        }
        
        var doesExist: Bool
        let appPath: String
        if #available(iOS 16.0, *) {
            doesExist = FileManager.default.fileExists(atPath: appSupportDir.path())
            appPath = appSupportDir.path()
        } else {
            var isDir: ObjCBool = true
            doesExist = FileManager.default.fileExists(atPath: appSupportDir.path, isDirectory: &isDir)
            appPath = appSupportDir.path
        }
        
        if !doesExist {
            try FileManager.default.createDirectory(atPath: appPath, withIntermediateDirectories: true)
        }
        
        if #available(iOS 16.0, *) {
            doesExist = FileManager.default.fileExists(atPath: appSupportDir.path())
        } else {
            var isDir: ObjCBool = true
            doesExist = FileManager.default.fileExists(atPath: appSupportDir.path, isDirectory: &isDir)
        }
        
        if #available(iOS 16.0, *) {
            let created = FileManager.default.createFile(atPath: localFilePath.path(), contents: data)
            if !created {
                throw TikTokenError.file
            }
        } else {
            let created = FileManager.default.createFile(atPath: localFilePath.path, contents: data)
            if !created {
                throw TikTokenError.file
            }
        }
    }
    
    func getBpeFile(fileName: String) throws -> URL? {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        // Should always have at least one value, but just in case
        guard let appSupportDir = appSupport.first else {
            throw TikTokenError.file
        }
        
        let localFilePath: URL
        if #available(iOS 16.0, *) {
            localFilePath = appSupportDir.appending(path: fileName, directoryHint: .notDirectory)
        } else {
            localFilePath = appSupportDir.appendingPathComponent(fileName, isDirectory: false)
        }
        
        let doesExist: Bool
        if #available(iOS 16.0, *) {
            doesExist = FileManager.default.fileExists(atPath: localFilePath.path())
        } else {
            var isDir: ObjCBool = false
            doesExist = FileManager.default.fileExists(atPath: localFilePath.path, isDirectory: &isDir)
        }
        
        return doesExist ? localFilePath : nil
    }
    
    func getLocalVocabLocation() throws -> URL? {
        guard let remoteUrl = URL(string: remoteUrlString) else {
            throw TikTokenError.invalidVocabParams
        }
        
        return try getBpeFile(fileName: remoteUrl.lastPathComponent)
    }
    
    func getLocalVocabEncoderLocation() throws -> URL? {
        // If there isn't one just say it exists so we won't try to download nothing
        guard let encoderString = encoderUrlString else {
            return nil
        }
        
        guard let encoderUrl = URL(string: encoderString) else {
            throw TikTokenError.file
        }
        
        return try getBpeFile(fileName: encoderUrl.lastPathComponent)
    }
}

internal extension Vocab {
    static var gpt2: Vocab {
        Vocab(name: "gpt2",
              remoteUrlString: "https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe",
              encoderUrlString: "https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json",
              explicitNVocab: 50257,
              pattern: "'(?:[sdmt]|ll|ve|re)| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+",
              specialTokens: [SpecialTokenConstants.ENDOFTEXT.rawValue: 50256])
    }
    
    static var r50kBase: Vocab {
        Vocab(name: "r50k_base",
              remoteUrlString: "https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken",
              explicitNVocab: 50257,
              pattern: "'(?:[sdmt]|ll|ve|re)| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+",
              specialTokens: [SpecialTokenConstants.ENDOFTEXT.rawValue: 50256])
    }
    
    static var p50kBase: Vocab {
        Vocab(name: "p50k_base",
              remoteUrlString: "https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken",
              explicitNVocab: 50281,
              pattern: "'(?:[sdmt]|ll|ve|re)| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+",
              specialTokens: [SpecialTokenConstants.ENDOFTEXT.rawValue: 50256])
    }
    
    static var p50kEdit: Vocab {
        Vocab(name: "p50k_edit",
              remoteUrlString: "https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken",
              pattern: "'(?:[sdmt]|ll|ve|re)| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+",
              specialTokens: [
                SpecialTokenConstants.ENDOFTEXT.rawValue: 50256,
                SpecialTokenConstants.FIM_PREFIX.rawValue: 50281,
                SpecialTokenConstants.FIM_MIDDLE.rawValue: 50282,
                SpecialTokenConstants.FIM_SUFFIX.rawValue: 50283
              ])
    }
    
    static var cl100kBase: Vocab {
        Vocab(name: "cl100k_base",
              remoteUrlString: "https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken",
              pattern: "'(?i:[sdmt]|ll|ve|re)|[^\\r\n\\p{L}\\p{N}]?+\\p{L}+|\\p{N}{1,3}| ?[^\\s\\p{L}\\p{N}]++[\\r\\n]*|\\s*[\\r\\n]|\\s+(?!\\S)|\\s+",
              specialTokens: [
                SpecialTokenConstants.ENDOFTEXT.rawValue: 100257,
                SpecialTokenConstants.FIM_PREFIX.rawValue: 100258,
                SpecialTokenConstants.FIM_MIDDLE.rawValue: 100259,
                SpecialTokenConstants.FIM_SUFFIX.rawValue: 100260,
                SpecialTokenConstants.ENDOFPROMPT.rawValue: 100276
              ])
    }
    
    static var o200kBase: Vocab {
        Vocab(name: "o200k_base",
              remoteUrlString: "https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken",
              pattern: [
                "[^\\r\\n\\p{L}\\p{N}]?[\\p{Lu}\\p{Lt}\\p{Lm}\\p{Lo}\\p{M}]*[\\p{Ll}\\p{Lm}\\p{Lo}\\p{M}]+(?i:'s|'t|'re|'ve|'m|'ll|'d)?",
                "[^\\r\\n\\p{L}\\p{N}]?[\\p{Lu}\\p{Lt}\\p{Lm}\\p{Lo}\\p{M}]+[\\p{Ll}\\p{Lm}\\p{Lo}\\p{M}]*(?i:'s|'t|'re|'ve|'m|'ll|'d)?",
                "\\p{N}{1,3}",
                " ?[^\\s\\p{L}\\p{N}]+[\\r\\n/]*",
                "\\s*[\\r\\n]+",
                "\\s+(?!\\S)",
                "\\s+"
            ].joined(separator: "|"),
              specialTokens: [
                SpecialTokenConstants.ENDOFTEXT.rawValue: 199999,
                SpecialTokenConstants.FIM_PREFIX.rawValue: 200018
              ])
    }
    
    static var all: [Vocab] = [.gpt2, .r50kBase, .p50kBase, .p50kEdit, .cl100kBase, .o200kBase]
}
