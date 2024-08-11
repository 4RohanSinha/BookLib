//
//  BookNoteViewQuickThoughtTableCells.swift
//  BookReview
//
//  Created by Rohan Sinha on 10/2/21.
//

import UIKit

class BookNoteViewTypedQuickThoughtTableCell: UITableViewCell {
    @IBOutlet weak var typedOutThoughtTextView: UITextView!
}


class BookNoteViewScannedQuickThoughtTableCell: UITableViewCell {
    
    @IBOutlet weak var scannedThoughtImageView: UIImageView!
    
    @IBOutlet weak var loadingImageViewActivityIndicator: UIActivityIndicatorView!
    
    private var _loadingImg: Bool = false
    
    var loadingImage: Bool {
        get {
            return _loadingImg
        } set {
            _loadingImg = newValue
            scannedThoughtImageView.isHidden = _loadingImg
            loadingImageViewActivityIndicator.isHidden = !_loadingImg
            _loadingImg ? loadingImageViewActivityIndicator.startAnimating() : loadingImageViewActivityIndicator.stopAnimating()
        }
    }
    
}
