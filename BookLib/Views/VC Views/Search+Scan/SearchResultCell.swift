//
//  SearchResultCell.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/25/21.
//

import UIKit

enum SearchResultCellButtonType {
    case added
    case new
    
    func configureAddButton(_ button: UIButton) {
            switch self {
            case .added:
                button.tintColor = .systemGreen
                button.setImage(UIImage(systemName: "checkmark"), for: .normal)
            case .new:
                button.tintColor = .white
                button.setImage(UIImage(systemName: "plus.app"), for: .normal)
            }
    }
    
    func configureAddButton(_ button: UIBarButtonItem) {
            switch self {
            case .added:
                button.tintColor = .systemGreen
                button.image = UIImage(systemName: "checkmark")
            case .new:
                button.tintColor = .systemBlue
                button.image = UIImage(systemName: "plus.app")
            }
    }
}

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var isbnTitle: UILabel!
    @IBOutlet weak var isbn10Lbl: UILabel!
    @IBOutlet weak var isbn13Lbl: UILabel!
    @IBOutlet weak var publisherLabel: UILabel!
    @IBOutlet weak var pageCountLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    var addBookHandler: (() -> Void)?
    var infoBookHandler: (() -> Void)?
    
    func configureView(withBookInformation information: BookInformation) {

        selectionStyle = .none
        
        titleLabel.text = information.title
        authorLabel.text = information.authors?.joined(separator: ", ") ?? "No information"

        isbn10Lbl.text = information.isbn10 ?? "Unavailable"
        isbn13Lbl.text = information.isbn13 ?? "Unavailable"
        
        publisherLabel.text = information.publisher ?? "No information"
        pageCountLabel.text = information.pageCount != nil ? String(describing: information.pageCount!) : "No information"
    }
    
    @IBAction func onAdd_btnTap(_ sender: Any) {
        addBookHandler?()
        addButton.isEnabled = false
        SearchResultCellButtonType.added.configureAddButton(addButton)
    }
    
    @IBAction func onInfo_btnTap(_ sender: Any) {
        infoBookHandler?()
    }
    
}
