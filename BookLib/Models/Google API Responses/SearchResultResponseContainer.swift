//
//  SearchResultResponseContainer.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/25/21.
//

import Foundation

struct SearchResultResponseContainer: Codable {
    var kind: String
    var totalItems: Int
    var items: [SearchResultBookContainer]
}
