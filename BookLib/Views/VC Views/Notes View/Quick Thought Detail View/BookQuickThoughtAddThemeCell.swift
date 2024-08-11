//
//  BookQuickThoughtAddThemeCell.swift
//  BookReview
//
//  Created by Rohan Sinha on 10/30/21.
//

import UIKit

class BookQuickThoughtAddThemeCell: UITableViewCell {
    
    enum CurrentMode {
        case added
        case not_part
    }
    
    @IBOutlet weak var themeLabel: UITextField!
    @IBOutlet weak var addDeleteBtn: UIButton!
    var currentMode: CurrentMode = .not_part
    
    var addHandler: (() -> ())?
    var deleteHandler: (() -> ())?

    func configureCell(theme: BookTheme, note: BookNoteQuickThought) {
        themeLabel.text = theme.title
        if let noteThemes = note.themes {
            if noteThemes.contains(theme) {
                addDeleteBtn.setImage(UIImage(systemName: Constants.deleteButtonSystemName), for: .normal)
                currentMode = .added
                layer.borderWidth = 3.0
                layer.borderColor = UIColor.systemBlue.cgColor
                return
            }
        }
        
        addDeleteBtn.setImage(UIImage(systemName: Constants.addButtonSystemName), for: .normal)
        layer.borderWidth = 0.0
        currentMode = .not_part
    }
    
    @IBAction func onAddDelete_btnTap(_ sender: Any) {
        if currentMode == .added {
            deleteHandler?()
            addDeleteBtn.setImage(UIImage(systemName: Constants.addButtonSystemName), for: .normal)
            layer.borderWidth = 0.0
            currentMode = .not_part
        } else if currentMode == .not_part {
            addHandler?()
            addDeleteBtn.setImage(UIImage(systemName: Constants.deleteButtonSystemName), for: .normal)
            currentMode = .added
            layer.borderWidth = 3.0
            layer.borderColor = UIColor.systemBlue.cgColor
        }
    }
}
