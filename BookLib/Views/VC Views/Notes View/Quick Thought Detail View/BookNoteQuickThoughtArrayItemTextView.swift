//
//  BookNoteQuickThoughtArrayItemTextView.swift
//  BookReview
//
//  Created by Rohan Sinha on 10/9/21.
//

import UIKit

class BookNoteQuickThoughtArrayItemTextView: UITextView {

    var indexPathInQuickThoughtTable: IndexPath?
    
    private var textIsPlaceholder: Bool = false
    
    var placeholderTapGestureRecognizer: UITapGestureRecognizer?
    var placeholder: String = "Tap here to edit quick thought..."
    
    var hasPlaceholder: Bool {
        set {
            textIsPlaceholder = newValue
            if newValue {
                self.text = placeholder
            } else if self.text == placeholder {
                self.text = ""
            }
        } get {
            return textIsPlaceholder
        }
    }
    
    @objc func removePlaceholder() {
        if hasPlaceholder {
            hasPlaceholder = false
        }
    }
    
}
