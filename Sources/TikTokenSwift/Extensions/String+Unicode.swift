import Foundation

extension String {
    func convertFromUnicodeString() -> String? {
        // Swift uses ICU values. Convert from Hex by using special key Hex-Any
        // Info yoinked from https://unicode-org.github.io/icu/userguide/transforms/general/#basic-ids
        let hexTransform = StringTransform("Hex-Any")
        return self.applyingTransform(hexTransform, reverse: false)
    }
    
    func convertFromPythonHexCodeToUnicodeCode() -> String {
        // In Python the '\x' modifier means the next two characters are a hex value
        let hexRegexStr = "\\\\x(?i:(\\d|[a-f])){2}"
        guard let hexRegex = try? NSRegularExpression(pattern: hexRegexStr) else {
            return self
        }
        var stringCopy = self
        let matches = hexRegex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        for match in matches {
            if let range = Range(match.range, in: self) {
                let matchedStr = String(self[range])
                let matchedStrSansHexMod = matchedStr.replacingOccurrences(of: "\\x", with: "")
                if (matchedStrSansHexMod.count == 4) {
                    continue
                }
                let numZeroToAppend = 4 - matchedStrSansHexMod.count
                var zeroString = ""
                for _ in 0..<numZeroToAppend {
                    zeroString += "0"
                }
                let newNumString = "\\u\(zeroString + matchedStrSansHexMod)"
                stringCopy = stringCopy.replacingOccurrences(of: matchedStr, with: newNumString)
            }
        }
        return stringCopy
    }
}
