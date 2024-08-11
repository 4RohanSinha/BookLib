//
//  AdvancedSearchView.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/24/21.
//

import UIKit

class AdvancedSearchView: UIViewRounded {

    @IBOutlet weak var advancedSearchItemsLabel: UILabel!
    
    func configureLabel(withQuery query: SearchQuery) {
        var composedTextArr: [String] = []
        
        if query.title != nil {
            composedTextArr.append("Title")
        }
        
        if query.author != nil {
            composedTextArr.append("Author")
        }
        
        if query.publisher != nil {
            composedTextArr.append("Publisher")
        }
        
        if query.isbn != nil {
            composedTextArr.append("ISBN")
        }
        
        let composedText = composedTextArr.count == 0 ? "Tap here to configure" : composedTextArr.joined(separator: ", ")
                
        advancedSearchItemsLabel.text = composedText
    }
    
}
