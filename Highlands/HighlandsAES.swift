//
//  HighlandsAES.swift
//  Highlands
//
//  Created by Raiden Honda on 1/18/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation
import CryptoSwift

public class HighlandsAES {
    
    private let key : String = "9b9b943e7e5f16937d864e70d580bf9e"
    private let iv : String = "400959b87f365632"
    
    // Test Vectors (http://www.inconteam.com/software-development/41-encryption/55-aes-test-vectors#aes-cbc-256)
//    private let key : String = "603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"
//    private let iv : String = "000102030405060708090A0B0C0D0E0F"
//    private let secret : String = "6bc1bee22e409f96e93d7e117393172a"
//    private let cipher : String = "f58c4c04d6e5f1ba779eabfb5f7bfbd6"
    
    func encrypt(secret : String) throws -> String {
        let secretArray = Array(secret.utf8)
        let encrypted: [UInt8] = try AES(key: key, iv: iv, blockMode: .CBC).encrypt(secretArray)

        let cipher = self.byteArrayToBase64(encrypted)
        return cipher
    }
    
    func decrypt(cipher : String) throws -> String {
        if let result = base64ToByteArray(cipher) {
            let decrypted: [UInt8] = try AES(key: key, iv: iv, blockMode: .CBC).decrypt(result)
            let decryptedData = NSData.withBytes(decrypted)
            if let secret = NSString(data: decryptedData, encoding: NSUTF8StringEncoding) as? String {
                return secret
            }
        }
        return ""
    }
    
    func byteArrayToBase64(bytes: [UInt8]) -> String {
        let nsdata = NSData(bytes: bytes, length: bytes.count)
        let base64Encoded = nsdata.base64EncodedStringWithOptions([]);
        return base64Encoded;
    }
    
    func base64ToByteArray(base64String: String) -> [UInt8]? {
        if let nsdata = NSData(base64EncodedString: base64String, options: []) {
            var bytes = [UInt8](count: nsdata.length, repeatedValue: 0)
            nsdata.getBytes(&bytes, length: bytes.count)
            return bytes
        }
        return nil // Invalid input
    }
}
