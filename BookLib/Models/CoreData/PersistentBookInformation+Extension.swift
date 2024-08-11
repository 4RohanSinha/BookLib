//
//  PersistentBookInformation+Extension.swift
//  BookReview
//
//  Created by Rohan Sinha on 1/6/22.
//

import Foundation

extension PersistentBookInformation {
    var codableBookInformation: BookInformation {
        return BookInformation(persistentBookInformation: self)
    }
}
