//
//  ConfigureAdvancedSearchViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/25/21.
//

import UIKit

class ConfigureAdvancedSearchViewController: UIViewController {

    @IBOutlet weak var titleTextField:  UITextField!
    @IBOutlet weak var authorTextField: UITextField!
    @IBOutlet weak var isbnTextField: UITextField!
    @IBOutlet weak var publisherTextField: UITextField!
    @IBOutlet weak var submitSearchView: UIView!
    
    var searchQuery: SearchQuery!
    
    var activeTextField: UITextField?
    var keyboardMoved: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchInputAccessoryButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 60))
        searchInputAccessoryButton.backgroundColor = #colorLiteral(red: 0.3450980392, green: 0.337254902, blue: 0.8392156863, alpha: 1)
        searchInputAccessoryButton.setTitle("Search", for: .normal)
        searchInputAccessoryButton.titleLabel?.font = .systemFont(ofSize: 25.0, weight: .light)
        searchInputAccessoryButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        searchInputAccessoryButton.addTarget(self, action: #selector(saveReconfiguredSearch), for: .touchUpInside)
        
        titleTextField.text = searchQuery.title
        titleTextField.clearButtonMode = .whileEditing
        titleTextField.delegate = self
        titleTextField.inputAccessoryView = searchInputAccessoryButton
        
        authorTextField.text = searchQuery.author
        authorTextField.clearButtonMode = .whileEditing
        authorTextField.delegate = self
        authorTextField.inputAccessoryView = searchInputAccessoryButton

        isbnTextField.text = searchQuery.isbn
        isbnTextField.clearButtonMode = .whileEditing
        isbnTextField.delegate = self
        isbnTextField.inputAccessoryView = searchInputAccessoryButton

        publisherTextField.text = searchQuery.publisher
        publisherTextField.clearButtonMode = .whileEditing
        publisherTextField.delegate = self
        publisherTextField.inputAccessoryView = searchInputAccessoryButton

        let submitGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(saveReconfiguredSearch))
        submitSearchView.addGestureRecognizer(submitGestureRecognizer)
        
        let dismissKeyboardGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(dismissKeyboardGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardNotifications()
    }
    
    func getText(from textField: UITextField) -> String? {
        return textField.text == "" ? nil : textField.text
    }
    
    @objc func saveReconfiguredSearch() {
        searchQuery.title = getText(from: titleTextField)
        searchQuery.author = getText(from: authorTextField)
        searchQuery.isbn = getText(from: isbnTextField)
        searchQuery.publisher = getText(from: publisherTextField)
        
        
        if let encodedSearchQuery = try? JSONEncoder().encode(searchQuery) {
            UserDefaults.standard.set(encodedSearchQuery, forKey: "searchQuery")
        }
        
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func dismissKeyboard() {
        activeTextField?.resignFirstResponder()
    }

}


extension ConfigureAdvancedSearchViewController {
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func getKeyboardFrame(_ notification: Notification) -> CGRect {
        let info = notification.userInfo!
        return (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    }
    
    func addKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let keyboardHeight = getKeyboardHeight(notification)
        let keyboardFrame = getKeyboardFrame(notification)
        if let activeFrame = activeTextField?.frame {
            if (keyboardFrame.contains(activeFrame) || keyboardFrame.minY < activeFrame.maxY) {
                keyboardMoved = true
                view.frame.origin.y = -keyboardHeight
            } else if (activeFrame.minY+keyboardHeight) < keyboardFrame.minY && keyboardMoved == true {
                keyboardMoved = false
                view.frame.origin.y += keyboardHeight
            } else if keyboardMoved == nil {
                keyboardMoved = false
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        if keyboardMoved == true {
            let keyboardHeight = getKeyboardHeight(notification)
            view.frame.origin.y += keyboardHeight
        }
        
        keyboardMoved = nil
    }
}

extension ConfigureAdvancedSearchViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
}
