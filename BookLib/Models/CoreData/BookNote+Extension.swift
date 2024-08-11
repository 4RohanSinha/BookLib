//
//  BookNoteType.swift
//  BookReview
//
//  Created by Rohan Sinha on 9/5/21.
//

import Foundation

enum BookNoteQuickThoughtArrayItemType: Int32 {
    case scanned
    case typed
    case empty
    case error
}

extension BookNote {
    public override func awakeFromInsert() {
        typeIdentifier = 1
    }
}

extension BookNoteQuickThoughtArrayItem {
    var type: BookNoteQuickThoughtArrayItemType {
        if typedText != nil && scannedPhotoData == nil {
            return .typed
        } else if scannedPhotoData != nil && typedText == nil {
            return .scanned
        } else if scannedPhotoData != nil && typedText != nil {
            return .scanned
        } else if scannedPhotoData == nil && typedText == nil {
            return .empty
        }
        
        return .error
    }
}

extension BookNoteQuickThought {
    var nextQuickThoughtId: Int {
        guard let quickThoughtItemsSet = arrayOfThoughts as? Set<BookNoteQuickThoughtArrayItem> else { return -1 }
        let quickThoughtArr = Array(quickThoughtItemsSet)
        
        if quickThoughtArr.count > 0 {
            let quickThoughtIds = quickThoughtArr.map { $0.quickThoughtId }
            return Int(quickThoughtIds.max() ?? 0)+1
        }
        
        return 0
    }
}
