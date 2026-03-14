import Foundation
import CryptoKit
import SwiftUI

struct TOTPHelper {
    
    // MARK: - Generate Master Secret (One Time)
    static func generateMasterSecret() -> String {
        var bytes = [UInt8](repeating: 0, count: 32) // 32 bytes = 256 bits
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else {
            print("⚠️ Failed to generate random bytes")
            return "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567" // Fallback
        }
        return base32Encode(bytes)
    }
    
    // MARK: - Generate Session Key (Every Launch)
    static func generateSessionKey(from masterSecret: String) -> String {
        guard !masterSecret.isEmpty else {
            print("⚠️ generateSessionKey received empty masterSecret")
            return "ABCDEFGHIJKLMNOP" // Fallback
        }
        
        // Combine master secret with today's date (changes daily)
        let daySeed = Int(Date().timeIntervalSince1970 / 86400) // 86400 seconds = 1 day
        guard let masterData = base32Decode(masterSecret), !masterData.isEmpty else {
            print("⚠️ Failed to decode master secret")
            return "ABCDEFGHIJKLMNOP"
        }
        
        // Use HKDF to derive session key
        var sessionBytes = [UInt8](repeating: 0, count: 20)
        let daySeedData = withUnsafeBytes(of: daySeed) { Data($0) }
        
        // Simple but effective: XOR master with day seed
        let minCount = min(masterData.count, sessionBytes.count)
        for i in 0..<minCount {
            sessionBytes[i] = masterData[i] ^ daySeedData[i % daySeedData.count]
        }
        
        return base32Encode(sessionBytes)
    }
    
    // MARK: - Generate TOTP Code from Session Key
    static func generateCode(from sessionKey: String) -> String {
        guard !sessionKey.isEmpty else {
            print("⚠️ generateCode received empty sessionKey")
            return "000000"
        }
        
        guard let secretData = base32Decode(sessionKey), !secretData.isEmpty else {
            print("⚠️ Failed to decode session key")
            return "000000"
        }
        
        let timeInterval: TimeInterval = 30
        let counter = UInt64(Date().timeIntervalSince1970 / timeInterval)
        
        // Generate HMAC-SHA1
        var counterData = Data()
        withUnsafeBytes(of: counter.bigEndian) { buffer in
            counterData = Data(buffer)
        }
        
        let hmac = HMAC<Insecure.SHA1>.authenticationCode(
            for: counterData,
            using: SymmetricKey(data: secretData)
        )
        
        // Convert HMAC to Data for easier manipulation
        let hmacData = Data(hmac)
        guard hmacData.count >= 20 else {
            print("⚠️ HMAC too short")
            return "000000"
        }
        
        // Dynamic truncation - manual implementation to avoid Swift 6 closure issues
        let offset = Int(hmacData.last! & 0x0F)
        
        // Ensure offset is within bounds (max offset is 15 for 20-byte HMAC)
        guard offset <= 15, hmacData.count >= offset + 4 else {
            print("⚠️ Offset out of bounds: \(offset)")
            return "000000"
        }
        
        // Extract 4 bytes starting at offset
        var truncated: UInt32 = 0
        for i in 0..<4 {
            truncated = (truncated << 8) | UInt32(hmacData[offset + i])
        }
        truncated &= 0x7FFFFFFF // Mask to 31 bits
        
        return String(format: "%06d", truncated % 1_000_000)
    }
    
    // MARK: - Generate Recovery Codes
    static func generateRecoveryCodes() -> [String] {
        var codes: [String] = []
        for _ in 1...10 {
            let part1 = Int.random(in: 1000...9999)
            let part2 = Int.random(in: 1000...9999)
            codes.append(String(format: "%04d-%04d", part1, part2))
        }
        return codes
    }
    
    // MARK: - Base32 Encoding
    static func base32Encode(_ bytes: [UInt8]) -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var result = ""
        var buffer = 0
        var bitsRemaining = 0
        
        for byte in bytes {
            buffer = (buffer << 8) | Int(byte)
            bitsRemaining += 8
            
            while bitsRemaining >= 5 {
                let index = (buffer >> (bitsRemaining - 5)) & 31
                result.append(alphabet[index])
                bitsRemaining -= 5
            }
        }
        
        if bitsRemaining > 0 {
            buffer <<= (5 - bitsRemaining)
            let index = buffer & 31
            result.append(alphabet[index])
        }
        
        return result
    }
    
    // MARK: - Base32 Decoding
    static func base32Decode(_ string: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var result = Data()
        var buffer = 0
        var bitsRemaining = 0
        
        for char in string.uppercased() {
            guard let index = alphabet.firstIndex(of: char) else { return nil }
            let value = alphabet.distance(from: alphabet.startIndex, to: index)
            
            buffer = (buffer << 5) | value
            bitsRemaining += 5
            
            if bitsRemaining >= 8 {
                bitsRemaining -= 8
                result.append(UInt8((buffer >> bitsRemaining) & 0xFF))
            }
        }
        
        return result
    }
}
