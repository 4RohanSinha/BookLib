//
//  ReadingListBookView.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/19/21.
//

import UIKit
import QuartzCore

class ReadingListBookView: UIViewRounded {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var authorLbl: UITextField!
    @IBOutlet weak var isbn10Lbl: UILabel!
    @IBOutlet weak var isbn13Lbl: UILabel!
    @IBOutlet weak var publisherLbl: UILabel!
    @IBOutlet weak var pageCountLbl: UILabel!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var coverActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var coverUnavailableLbl: UILabel!
    
    private var _loadingCover: Bool = false
    var loadingCover: Bool {
        get {
            return _loadingCover
        } set {
            _loadingCover = newValue
            coverView.isHidden = _loadingCover
            coverActivityIndicator.isHidden = !_loadingCover
            _loadingCover ? coverActivityIndicator.startAnimating() : coverActivityIndicator.stopAnimating()
        }
    }
    
    override func configureView() {
        super.configureView()
    }
    
    func configureCoverImage(image: UIImage?) {
        loadingCover = false
        if let image = image {
            coverView.image = image
            coverUnavailableLbl.isHidden = true
        } else {
            coverUnavailableLbl.isHidden = false
        }
    }
    
}
