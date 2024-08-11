//
//  VerifyIsbnViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/17/21.
//

import UIKit
import MLKit

class VerifyIsbnViewController: UIViewController {

    @IBOutlet weak var possibleIsbnsTableView: UITableView!
    @IBOutlet weak var finalIsbnTextField: UITextField!
    @IBOutlet weak var submitCustomIsbnBtn: UIImageView!
    @IBOutlet weak var scanningActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scanningActivityMsg: UIStackView!
    @IBOutlet weak var scannedImageView: UIImageView!
    @IBOutlet weak var loadingLbl: UILabel!
    
    var imageToScan: UIImage?
    var tblCellColors: [UIColor] = []
    
    var possibleIsbns: [Barcode] = []
    
    let barcodeScanner: BarcodeScanner = {
        return BarcodeScanner.barcodeScanner()
    }()
    
    var storeIsbn: ((String) -> Void)?
    
    var keyboardMoved: Bool?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let dismissKeyboardTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTapGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissKeyboardTapGestureRecognizer)
        
        possibleIsbnsTableView.delegate = self
        possibleIsbnsTableView.dataSource = self
        
        possibleIsbnsTableView.separatorStyle = .none
        possibleIsbnsTableView.backgroundColor = .black
        
        finalIsbnTextField.clearButtonMode = .whileEditing
        
        guard let imageToScan = imageToScan else { return }
        scannedImageView.image = imageToScan
        configureCustomIsbnBtn()
        getIsbns(from: imageToScan)
        configureActivityIndicator(scanning: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardNotifications()
    }
    
    func configureVC(image: UIImage) {
        imageToScan = image
    }
    
    func getIsbns(from image: UIImage) {
        let visionImage = VisionImage(image: image)
        visionImage.orientation = image.imageOrientation
        barcodeScanner.process(visionImage) { barcodes, error in
            if let barcodes = barcodes {

                self.possibleIsbns = barcodes.filter { $0.valueType == .ISBN }
                
                var lastColor: UIColor = .systemOrange
                for _ in barcodes {
                    
                    var randomColor = Constants.colors.randomElement() ?? .systemOrange
                    
                    if randomColor == lastColor {
                        randomColor = Constants.colors.randomElement() ?? .systemOrange
                    }
                    
                    self.tblCellColors.append(randomColor)
                    
                    lastColor = randomColor
                    
                }
                
                DispatchQueue.main.async {
                    self.possibleIsbnsTableView.reloadData()
                    //self.finalIsbnTextField.text = self.possibleIsbns[0].rawValue
                    self.configureActivityIndicator(scanning: false)
                }
            }
        }
    }

    //MARK: UI functions
    
    func configureCustomIsbnBtn() {
        let submitTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(VerifyIsbnViewController.saveCustomISBN))
        submitCustomIsbnBtn.isUserInteractionEnabled = true
        submitCustomIsbnBtn.addGestureRecognizer(submitTapRecognizer)
    }
    
    func configureActivityIndicator(scanning: Bool) {
        //scanningActivityMsg.isHidden = !scanning
        scanningActivityIndicator.isHidden = !scanning
        possibleIsbnsTableView.isHidden = scanning
        
        if scanning {
            scanningActivityIndicator.startAnimating()
            loadingLbl.text = "Scanning"
        } else {
            scanningActivityIndicator.stopAnimating()
            if possibleIsbns.count >= 1 {
                loadingLbl.text = "Edit and confirm the ISBN below"
            } else {
                loadingLbl.text = "Unable to detect any ISBNs"
            }
        }
    }
    
    //MARK: IbAction
    @IBAction func onCancel_btnTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onRescan_btnTap(_ sender: Any) {
        let cameraImagePicker = UIImagePickerController()
        cameraImagePicker.sourceType = .camera
        cameraImagePicker.delegate = self
        present(cameraImagePicker, animated: true, completion: nil)
    }
    
    @objc func saveCustomISBN(_ sender: Any) {
        if let customIsbn = finalIsbnTextField.text {
            if HelperFunctions.isValidIsbn(isbn: customIsbn) {
                storeIsbn?(customIsbn)
                dismiss(animated: true, completion: nil)
            } else {
                alert(title: "Error", msg: "ISBN is invalid")
            }
        }
    }
    
}


extension VerifyIsbnViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return possibleIsbns.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "isbnVerifyScannedCell") as? VerifyIsbnTableViewCell else { return UITableViewCell() }
        
        cell.roundedView.configureLabelWithIsbn(isbn: possibleIsbns[indexPath.row].rawValue ?? "Unknown") //MARK: todo - handle optional this better
        cell.roundedView.backgroundColor = tblCellColors[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let determinedIsbn = possibleIsbns[indexPath.row].rawValue {
            storeIsbn?(determinedIsbn)
            dismiss(animated: true, completion: nil)
        }
        
    }
}


extension VerifyIsbnViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            possibleIsbns.removeAll(keepingCapacity: false)
            possibleIsbnsTableView.reloadData()
            
            configureActivityIndicator(scanning: true)
            configureVC(image: image)
            getIsbns(from: image)
            scannedImageView.image = imageToScan
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension VerifyIsbnViewController: UIGestureRecognizerDelegate {
    
    @objc func dismissKeyboard() {
        finalIsbnTextField.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return finalIsbnTextField.isFirstResponder
    }
}

extension VerifyIsbnViewController {
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
        if let activeFrame = finalIsbnTextField?.frame {
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
