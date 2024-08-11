//
//  SearchQuery.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/24/21.
//

import Foundation

class SearchQuery: Codable {
    
    
    var basicQuery: String?
    var title: String?
    var author: String?
    var publisher: String?
    var isbn: String?
    
    var isEmpty: Bool {
        return ((basicQuery == nil || basicQuery == "") && (title == nil || title == "") &&  (author == nil || author == "") && (publisher == nil || publisher == "") && (isbn == nil || isbn == ""))
    }
    
    var googleApiUrl: URL? {
        typealias GoogleAPISearchQueryEndpoints = GoogleBooksAPIClient.Endpoints

        var composedEndpoint = ""
        
        if let basicQuery = basicQuery {
            composedEndpoint += GoogleAPISearchQueryEndpoints.genericQuery(basicQuery).stringVal
        }
        
        if let title = title {
            composedEndpoint += GoogleAPISearchQueryEndpoints.titleQuery(title).stringVal
        }
        
        if let author = author {
            composedEndpoint += GoogleAPISearchQueryEndpoints.authorQuery(author).stringVal
        }
        
        
        if let publisher = publisher {
            composedEndpoint += GoogleAPISearchQueryEndpoints.publisherQuery(publisher).stringVal
        }
        
        if let isbn = isbn {
            composedEndpoint += GoogleAPISearchQueryEndpoints.isbnQuery(isbn).stringVal
        }
        
        var urlString = GoogleAPISearchQueryEndpoints.base_query + composedEndpoint
        
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString
        
        return URL(string: urlString)

    }
    
}
