//
//  BookNoteFolderItem+Extension.swift
//  BookReview
//
//  Created by Rohan Sinha on 9/17/21.
//

import Foundation


extension BookNoteFolderItem {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
