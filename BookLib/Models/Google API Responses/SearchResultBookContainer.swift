//
//  SearchResultBookContainer.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/25/21.
//

import Foundation

struct SearchResultBookContainer: Codable {
    var kind: String
    var id: String
    var etag: String
    var selfLink: String
    var volumeInfo: BookInformation
}
