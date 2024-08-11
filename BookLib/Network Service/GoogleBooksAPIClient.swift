//
//  GoogleBooksAPIClient.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/15/21.
//

import Foundation

//MARK: TODO - change to use API key
class GoogleBooksAPIClient {
    enum Endpoints {
        static let base_query = "https://www.googleapis.com/books/v1/volumes?q="
        case genericQuery(String)
        case titleQuery(String)
        case authorQuery(String)
        case publisherQuery(String)
        case subjectQuery(String)
        case isbnQuery(String)
        
        var stringVal: String {
            switch self {
            case .genericQuery(let query):
                return query
            case .titleQuery(let title):
                return "+intitle:\(title)"
            case .authorQuery(let author):
                return "+inauthor:\(author)"
            case .publisherQuery(let publisher):
                return "+inpublisher:\(publisher)"
            case .subjectQuery(let subject):
                return "+subject:\(subject)"
            case .isbnQuery(let isbn):
                return "+isbn:\(isbn)"
            }
        }
        
        var url: URL? {
            return URL(string: stringVal)
        }
        
    }
    
    class func searchBooks(withQuery query: SearchQuery, completion: ((SearchResultResponseContainer?, Error?) -> Void)?) -> URLSessionTask? {
        guard !query.isEmpty else { return nil }
        guard let googleApiUrl = query.googleApiUrl else { return nil }
        let task = URLSession.shared.dataTask(with: googleApiUrl) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion?(nil, error)
                }
                return
            }
            
            
            let decoder = JSONDecoder()
            
            do {
                let responseObject = try decoder.decode(SearchResultResponseContainer.self, from: data)
                completion?(responseObject, nil)
                
            } catch let error {
                completion?(nil, error)
            }
            
        }
        
        task.resume()
        
        return task
    }
    
    
}
