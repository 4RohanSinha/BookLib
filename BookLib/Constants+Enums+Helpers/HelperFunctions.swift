//
//  HelperFunctions.swift
//  BookReview
//
//  Created by Rohan Sinha on 1/3/22.
//

import Foundation

class HelperFunctions {
    class func convertHttpToHttps(httpUrl: String) -> String? {
        if var httpComponents = URLComponents(string: httpUrl) {
            httpComponents.scheme = "https"
            return httpComponents.string
        }
        
        return nil
    }
    
    class func isValidIsbn(isbn: String) -> Bool {
        return isValidIsbn10(isbn10String: isbn) || isValidIsbn13(isbn13String: isbn)
    }
    
    class func isValidIsbn10(isbn10String: String) -> Bool {
        let isbn10 = isbn10String.filter("0123456789X".contains)
        guard isbn10.count == 10 else { return false }
        
        var checkSum = 0
        var index = 0
        var lastCharacterString = ""
        var integerWeight = 10
        
        isbn10.forEach { character in
            if index == 9 {
                lastCharacterString = String(character)
                return
            } else {
                let digitString = String(character)
                
                if let digit = Int(digitString) {
                    checkSum += integerWeight*digit
                }
            }
            
            index += 1
            integerWeight -= 1
        }
        
        if lastCharacterString == "X" {
            return (checkSum + 10) % 11 == 0
        } else if let digit = Int(lastCharacterString) {
            return (checkSum + digit) % 11 == 0
        }
        
        return false
    }
    
    class func isValidIsbn13(isbn13String: String) -> Bool {
        let isbn13 = isbn13String.filter("0123456789".contains)
        guard isbn13.count == 13 else { return false }
        
        var checkSum = 0
        var index = 0
        var lastCharacterString = ""
        
        isbn13.forEach { character in
            
            if index == 12 {
                lastCharacterString = String(character)
                return
            } else {
                let digitString = String(character)
                
                if let digit = Int(digitString) {
                    if index % 2 == 0 {
                        checkSum += digit
                    } else {
                        checkSum += digit*3
                    }
                }
            }
            
            index += 1
        }
        
        if let lastDigit = Int(lastCharacterString) {
            return lastDigit == 10 - (checkSum % 10)
        }
        
        return false
    }
}
