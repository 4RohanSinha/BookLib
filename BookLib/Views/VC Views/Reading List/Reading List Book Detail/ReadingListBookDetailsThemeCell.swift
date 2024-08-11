//
//  ReadingListBookDetailsThemeCell.swift
//  BookReview
//
//  Created by Rohan Sinha on 8/11/21.
//

import UIKit

class ReadingListBookDetailsThemeCell: UITableViewCell {

    @IBOutlet weak var themeLbl: UILabel!
    @IBOutlet weak var arrowRightBtn: UIButton!
    @IBOutlet weak var arrowRightImg: UIImageView!
    var onThemeDetail_btnTapEventHandler: (() -> ())?
    weak var tableViewSwipeGestureRecognizer: UISwipeGestureRecognizer?
    
    func configureView() {
        arrowRightBtn.setTitle("", for: .normal)
        arrowRightBtn.addSubview(arrowRightImg)
    }
    
    override func awakeFromNib() {
        configureView()
    }
    
    @IBAction func seeThemeDetails() {
        onThemeDetail_btnTapEventHandler?()
    }

}
