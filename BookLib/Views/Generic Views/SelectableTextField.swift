//
//  SelectableTextField.swift
//  BookReview
//
//  Created by Rohan Sinha on 1/6/22.
//

import UIKit

class SelectableTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(cut) {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
}
