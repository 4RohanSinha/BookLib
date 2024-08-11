//
//  Constants.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/18/21.
//

import Foundation
import UIKit

class Constants {
    static let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue, .systemPurple]

    static let dateFormatter: DateFormatter = {
        var dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM y @ hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return dateFormatter
    }()
    
    static let addButtonSystemName = "plus.app"
    static let deleteButtonSystemName = "trash.fill"
    
}
