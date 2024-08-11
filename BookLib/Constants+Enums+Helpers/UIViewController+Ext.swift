//
//  UIViewController+Ext.swift
//  BookReview
//
//  Created by Rohan Sinha on 1/6/22.
//

import UIKit

extension UIViewController {
    func alert(title: String, msg: String) {
        let alertVC = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
}
