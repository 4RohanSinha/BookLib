//
//  UIViewRounded.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/17/21.
//

import UIKit

class UIViewRounded: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }
    
    func configureView() {
        layer.cornerRadius = 10.0
    }

}
