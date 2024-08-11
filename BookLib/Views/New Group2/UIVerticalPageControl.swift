//
//  UIVerticalPageControl.swift
//  BookReview
//
//  Created by Rohan Sinha on 8/10/21.
//

import UIKit

class UIVerticalPageControl: UIPageControl {

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }
    
    func configureView() {
        transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi)/2)
    }

}
