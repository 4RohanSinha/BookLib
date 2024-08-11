//
//  ScannedBookView.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/17/21.
//

import UIKit

class ScannedBookView: UIViewRounded {

    @IBOutlet weak var isbnLabel: UILabel!

    func configureLabelWithIsbn(isbn: String) {
        isbnLabel.text = "ISBN: \(isbn)"
    }

}
