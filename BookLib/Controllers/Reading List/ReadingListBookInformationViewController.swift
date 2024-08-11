//
//  ReadingListBookInformationViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 8/11/21.
//

import UIKit

class ReadingListBookInformationViewController: UIViewController {

    var bookInfo: BookInformation?
    
    @IBOutlet weak var bookCoverPhotoImgView: UIImageView!
    @IBOutlet weak var loadingImageActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingImageLbl: UILabel!
    @IBOutlet weak var novelTitleLbl: UILabel!
    @IBOutlet weak var authorLbl: UILabel!
    @IBOutlet weak var publisherLbl: UILabel!
    @IBOutlet weak var publishedDateLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UITextView!
    @IBOutlet weak var pageCountLbl: UILabel!
    @IBOutlet weak var printTypeLbl: UILabel!
    @IBOutlet weak var maturityRating: UILabel!
    @IBOutlet weak var isbn10Lbl: SelectableTextField!
    @IBOutlet weak var isbn13Lbl: SelectableTextField!
    @IBOutlet weak var addBookToReadingListBtn: UIBarButtonItem!
    
    var activeTextField: UITextField?
    var bookIsAdded: Bool?
    var onAddBtnTapClosure: (() -> ())?
    
    func configureViews() {
        
        configureRightBarButtonItem()
        
        let firstResponderGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(firstResponderGestureRecognizer)
        
        novelTitleLbl.text = bookInfo?.title
        authorLbl.text = "by \(bookInfo?.authors?.joined(separator: ", ") ?? "Unknown")"
        publisherLbl.text = "Publisher: \(bookInfo?.publisher ?? "Unavailable")"
        publishedDateLbl.text = "Published date: \(bookInfo?.publishedDate ?? "Unavailable")"

        pageCountLbl.text = "Page count: \((bookInfo?.pageCount != nil && bookInfo?.pageCount != 0) ? String(describing: (bookInfo?.pageCount)!) : "Unavailable")"
        
        descriptionLbl.text = bookInfo?.bookDescription ?? "Description unavailable"
        
        printTypeLbl.text = "Print type: \(bookInfo?.printType?.lowercased().replacingOccurrences(of: "_", with: " ") ?? "Unavailable")"
        maturityRating.text = "Maturity rating: \(bookInfo?.maturityRating?.lowercased().replacingOccurrences(of: "_", with: " ") ?? "Unavailable")"
        
        isbn10Lbl.text = "\(bookInfo?.isbn10 ?? "Unavailable")"
        isbn10Lbl.delegate = self
        isbn10Lbl.inputView = UIView(frame: CGRect.zero)

        isbn13Lbl.text = "\(bookInfo?.isbn13 ?? "Unavailable")"
        isbn13Lbl.delegate = self
        isbn13Lbl.inputView = UIView(frame: CGRect.zero)

    }
    
    func configureRightBarButtonItem() {
        if let bookIsAdded = bookIsAdded, let rightBarButtonItem = navigationItem.rightBarButtonItem {
            if bookIsAdded {
                rightBarButtonItem.isEnabled = false
                SearchResultCellButtonType.added.configureAddButton(rightBarButtonItem)
            } else {
                rightBarButtonItem.isEnabled = true
                SearchResultCellButtonType.new.configureAddButton(rightBarButtonItem)
            }
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func configureLoadingImageViews(completion: Bool, success: Bool?) {

        completion ? loadingImageActivityIndicator.stopAnimating() : loadingImageActivityIndicator.startAnimating()

        loadingImageActivityIndicator.isHidden = completion
        loadingImageLbl.isHidden = completion
        
        
        if let success = success {
            loadingImageLbl.isHidden = success
            if !success {
                loadingImageLbl.text = "Unable to load image"
            }
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        configureViews()
        fetchImageFromBook(withInfo: bookInfo)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func fetchImageFromBook(withInfo info: BookInformation?) {
        if let info = info, let imageLinks = info.imageLinks, let httpThumbnail = imageLinks.thumbnail, let thumbnail = HelperFunctions.convertHttpToHttps(httpUrl: httpThumbnail) {
            loadingImageLbl.text = "Loading cover image"
            configureLoadingImageViews(completion: false, success: nil)

            FetchImage.getImage(withUrl: thumbnail) { (data, error) in
                DispatchQueue.main.async {
                    if let data = data {
                        self.bookCoverPhotoImgView.image = UIImage(data: data)
                        self.configureLoadingImageViews(completion: true, success: true)
                    } else {
                        self.configureLoadingImageViews(completion: true, success: false)
                    }
                }
            }
        } else {
            configureLoadingImageViews(completion: true, success: false)
        }
    }
    
    @IBAction func onAdd_btnTap(_ sender: Any) {
        onAddBtnTapClosure?()
        addBookToReadingListBtn.isEnabled = false
        SearchResultCellButtonType.added.configureAddButton(addBookToReadingListBtn)
        if bookIsAdded != nil {
            bookIsAdded = true
        }
    }
    
    

}

extension ReadingListBookInformationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return activeTextField?.isFirstResponder == true
    }
    
    @objc func dismissKeyboard() {
        activeTextField?.resignFirstResponder()
    }
}

extension ReadingListBookInformationViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField
        activeTextField?.isHighlighted = true
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    
}
