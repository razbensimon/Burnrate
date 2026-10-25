import CommonCrypto
import Foundation

/// Unwraps Cursor IDE auth tokens sealed with Electron safe storage.
///
/// When `cursor.storage.authTokenEncryptionAtRest` is on, `cursorAuth/accessToken`
/// is stored as `cursor-safe-storage:v1:` plus the base64 of a `v10` AES-128-CBC
/// blob. The key is PBKDF2-HMAC-SHA1 of the "Cursor Safe Storage" keychain
/// password (salt `saltysalt`, 1003 rounds, 16 bytes). The IV is 16 spaces.
public enum CursorSafeStorage {
    public static let envelopePrefix = "cursor-safe-storage:v1:"

    private static let versionPrefix = Data("v10".utf8)
    private static let salt = Data("saltysalt".utf8)
    private static let iterations: UInt32 = 1003
    private static let keyLength = 16

    public static func isSealed(_ stored: String) -> Bool {
        stored.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(envelopePrefix)
    }

    /// Decrypts a sealed access token. Returns nil when the envelope, key, or padding is wrong.
    public static func decrypt(_ stored: String, password: String) -> String? {
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(envelopePrefix), !password.isEmpty else { return nil }

        let payload = String(trimmed.dropFirst(envelopePrefix.count))
        guard let blob = Data(base64Encoded: payload), blob.starts(with: versionPrefix) else {
            return nil
        }

        let ciphertext = blob.dropFirst(versionPrefix.count)
        guard ciphertext.count >= kCCBlockSizeAES128,
              ciphertext.count.isMultiple(of: kCCBlockSizeAES128),
              let key = deriveKey(password: password),
              let plain = aesCBCDecrypt(ciphertext: Data(ciphertext), key: key)
        else {
            return nil
        }

        let jwt = plain.trimmingCharacters(in: .whitespacesAndNewlines)
        return jwt.isEmpty ? nil : jwt
    }

    private static func deriveKey(password: String) -> Data? {
        let passwordData = Data(password.utf8)
        var key = Data(count: keyLength)
        let status: Int32 = key.withUnsafeMutableBytes { keyRaw in
            passwordData.withUnsafeBytes { passwordRaw in
                salt.withUnsafeBytes { saltRaw in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordRaw.bindMemory(to: Int8.self).baseAddress,
                        passwordData.count,
                        saltRaw.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
                        iterations,
                        keyRaw.bindMemory(to: UInt8.self).baseAddress,
                        keyLength
                    )
                }
            }
        }
        guard status == kCCSuccess else { return nil }
        return key
    }

    private static func aesCBCDecrypt(ciphertext: Data, key: Data) -> String? {
        let iv = Data(repeating: 0x20, count: kCCBlockSizeAES128)
        let outputCapacity = ciphertext.count + kCCBlockSizeAES128
        var output = Data(count: outputCapacity)
        var moved = 0
        let status: CCCryptorStatus = output.withUnsafeMutableBytes { outRaw in
            ciphertext.withUnsafeBytes { cipherRaw in
                key.withUnsafeBytes { keyRaw in
                    iv.withUnsafeBytes { ivRaw in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyRaw.baseAddress,
                            key.count,
                            ivRaw.baseAddress,
                            cipherRaw.baseAddress,
                            ciphertext.count,
                            outRaw.baseAddress,
                            outputCapacity,
                            &moved
                        )
                    }
                }
            }
        }
        guard status == kCCSuccess else { return nil }
        return String(data: output.prefix(moved), encoding: .utf8)
    }
}
