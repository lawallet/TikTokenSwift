import Foundation
import CryptoKit

struct Load {    
    static func loadTiktokenBpe(vocab: Vocab, decoder: FileDecoder = FileDecoder()) async throws -> BpeRanks {
        let vocabData = try await vocab.loadVocabData()
        var fileBpe = try decoder.decode(vocabData)
        addSpecialTokensToBpe(bpe: &fileBpe, specialTokens: vocab.specialTokens)
        return fileBpe
    }
    
    static func dataGymToMergeableBpeRanks(vocab: Vocab) async throws -> BpeRanks {
        let encoderData = try await vocab.loadVocabData()
        let encoderValidationData = try await vocab.loadVocabValidationData()
        var fileBpe = try createMergableBpeFromDataGym(vocabData: encoderData, encoderValidationData: encoderValidationData, specialTokens: vocab.specialTokens)
        // Add the special string to the rank
        addSpecialTokensToBpe(bpe: &fileBpe, specialTokens: vocab.specialTokens)
        return fileBpe
    }
    
    static func addSpecialTokensToBpe(bpe: inout BpeRanks, specialTokens: [String: Int]) {
        for key in specialTokens.keys {
            let utf8EncodedKey: [UInt8] = Array(key.utf8)
            bpe[utf8EncodedKey] = specialTokens[key]
        }
    }
    
    static func createMergableBpeFromDataGym(vocabData: Data, encoderValidationData: Data, specialTokens: [String: Int]) throws -> BpeRanks {
        let maxVal = Int(pow(2.0, 8))
        let rangeToMaxValue = 0...UInt8(maxVal-1)
        var theChars: [[UInt8]] = []
        var filtered = rangeToMaxValue.filter { currentCharacterValue in
            let unicodeValue = Unicode.Scalar(currentCharacterValue)
            let scaleVale = unicodeValue.properties.generalCategory
            // Logic obtained by adding values Python's isPrintable returned to a set and then adding the categories that weren't in that set to see what they were
            return unicodeValue.pythonIsPrintable && scaleVale != .spaceSeparator
        }
        var byteToByte: [Character: Int] = [:]
        for val in filtered {
            let valInt = Int(val)
            guard let wantedChar = Character(unicodeValue:valInt) else {
                throw TikTokenError.unicode
            }
            byteToByte[wantedChar] = valInt
            theChars.append(Array(wantedChar.utf8))
        }

        var n = 0
        for num in rangeToMaxValue {
            let valInt = Int(num)
            if !filtered.contains(num) {
                filtered.append(num)
                guard let wantedCharacter = Character(unicodeValue: maxVal + n) else {
                    throw TikTokenError.unicode
                }
                byteToByte[wantedCharacter] = valInt
                theChars.append(Array(wantedCharacter.utf8))
                n += 1
            }
        }
        
        if filtered.count != maxVal {
            throw TikTokenError.bpeCountMismatch(256, filtered.count)
        }
        
        var oldStyleFile: [(first: [UInt8], second: [UInt8])] = []
        var first: [UInt8] = []
        var second: [UInt8] = []
        var parseFirst = true
        var currLine = 0
        for byte in vocabData {
            // Have we hit the space in the line?
            if (byte == 32) {
                parseFirst = false
            } else if (byte == 10) { // Have we hit a new line?
                // gpt2's first line is a version string so skip it
                if (currLine == 0) {
                    currLine += 1
                    first = []
                    second = []
                    parseFirst = true
                    continue
                }
                parseFirst = true
                oldStyleFile.append((first: first, second: second))
                currLine += 1
                first = []
                second = []
            } else {
                if parseFirst {
                    first.append(byte)
                } else {
                    second.append(byte)
                }
            }
        }
        var bpeRanks: BpeRanks = [:]
        for num in rangeToMaxValue {
            let valInt = Int(num)
            let singleChar:[UInt8] = [filtered[valInt]]
            bpeRanks[singleChar] = valInt
        }
        n = bpeRanks.count
        for num in 0..<oldStyleFile.count {
            let currTuple = oldStyleFile[num]
            let mergedVal = mapCharsFor(mapDict: byteToByte, str: currTuple.first) + mapCharsFor(mapDict: byteToByte, str: currTuple.second)
            bpeRanks[mergedVal] = n
            n += 1
        }
        
        let gpt2Validated = UserDefaults.standard.object(forKey: "tiktokenGptValidated") as? Bool ?? false
        if !gpt2Validated {
            let isValid = validateBpeGymData(encoderJsonData: encoderValidationData, mergedBpe: bpeRanks, mapDict: byteToByte, specialTokens: specialTokens)
            if !isValid {
                throw TikTokenError.validation
            }
        }
        
        return bpeRanks
    }
    
    static func mapCharsFor(mapDict: [Character: Int], str: [UInt8]) -> [UInt8] {
        var strCopy = str
        strCopy.append(0)
        var ret: [UInt8] = []
        let currString = String(cString: strCopy)
        for char in currString {
            if let mappedChar = mapDict[char] {
                let map: UInt8 = UInt8(mappedChar)
                ret.append(map)
            }
            
        }
        return ret
    }
    
    static func validateBpeGymData(encoderJsonData: Data, mergedBpe: BpeRanks, mapDict: [Character: Int], specialTokens: [String: Int]) -> Bool {
        // Going old school since it's easier to compare dict to dict
        let encodedJson: [String:Int]
        do {
            encodedJson = try JSONSerialization.jsonObject(with: encoderJsonData, options: .fragmentsAllowed) as? [String:Int] ?? [:]
        } catch {
            return false
        }
        if encodedJson.count == 0 {
            return false
        }
        
        for key in encodedJson.keys {
            let dictVal = encodedJson[key]
            guard let convertedKey = key.convertFromUnicodeString() else {
                return false
            }
            let byteArr: [UInt8] = mapCharsFor(mapDict: mapDict, str: Array(convertedKey.utf8))
            let byteVal = mergedBpe[byteArr]
            if dictVal != byteVal && !specialTokens.keys.contains(key) {
                return false
            }
        }
        UserDefaults.standard.setValue(true, forKey: "tiktokenGptValidated")
        return true
    }
}
