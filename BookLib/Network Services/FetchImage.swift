//
//  FetchImage.swift
//  BookReview
//
//  Created by Rohan Sinha on 8/11/21.
//

import Foundation

class FetchImage {
    class func getImage(withUrl stringUrl: String, completion: @escaping ((Data?, Error?) -> ())) {
        guard let url = URL(string: stringUrl) else {
            completion(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion(nil, error)
                return
            }
            
            completion(data, nil)
            
        }
        
        task.resume()
    }
}
