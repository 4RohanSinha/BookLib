//
//  BookNoteThemeCollectionViewCell.swift
//  BookReview
//
//  Created by Rohan Sinha on 9/18/21.
//

import UIKit

class BookNoteThemeCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var themeLbl: UITextField!
    var cancelHandler: (() -> ())?
    
    @IBAction func onCancel_btnTap(_ sender: Any) {
        cancelHandler?()
    }
}
