//
//  ScanBarcodeViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/17/21.
//

import UIKit
import MLKit

class ScanBarcodeViewController: CoreDataStackViewController {

    @IBOutlet weak var isbnsTableView: UITableView!
    @IBOutlet weak var scan_btn: UIButton!
    @IBOutlet weak var uploadImg_btn: UIButton!
    @IBOutlet weak var clearIsbnsBtn: UIButton!
    
    var scannedIsbns: [String] = []
    let scan_btn_dimension: CGFloat = 50.0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        isbnsTableView.delegate = self
        isbnsTableView.dataSource = self
        isbnsTableView.separatorStyle = .none
        clearIsbnsBtn.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scan_btn.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        isbnsTableView.reloadData()
        if scannedIsbns.count > 0 {
            clearIsbnsBtn.isHidden = false
        }
    }
        
    //MARK: UI functions
    
    
    func createImagePicker(sourceType: UIImagePickerController.SourceType) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        return imagePicker
    }
    
    func openCameraForBarcodeScanning() {
        let cameraImagePicker = createImagePicker(sourceType: .camera)
        present(cameraImagePicker, animated: true, completion: nil)
    }
    
    func uploadImageForBarcodeScanning() {
        let albumImagePicker = createImagePicker(sourceType: .photoLibrary)
        present(albumImagePicker, animated: true, completion: nil)
    }
    
    //MARK:- IbActions
    
    @IBAction func onScan_btnTap(_ sender: Any) {
        openCameraForBarcodeScanning()
    }
    
    @IBAction func onUploadImg_btnTap(_ sender: Any) {
        uploadImageForBarcodeScanning()
        
    }
    
    @IBAction func clearISBNs(_ sender: Any) {
        scannedIsbns = []
        isbnsTableView.reloadData()
        clearIsbnsBtn.isHidden = true
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchBooksVC = segue.destination as? SearchBooksViewController, let searchQuery = sender as? SearchQuery, segue.identifier == "searchBooksByScannedIsbn" {
            searchBooksVC.searchQuery = searchQuery
            searchBooksVC.showsBarcodeResults = true
            searchBooksVC.dataController = dataController
        }
    }
    
}

extension ScanBarcodeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedIsbns.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "scannedBookTableViewCell") as? ScannedBookTableViewCell else { return UITableViewCell() }
        cell.selectionStyle = .none
        cell.roundedView.configureLabelWithIsbn(isbn: scannedIsbns[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedIsbn = scannedIsbns[indexPath.row]
        
        let searchQueryWithIsbn = SearchQuery()
        searchQueryWithIsbn.isbn = selectedIsbn
                
        performSegue(withIdentifier: "searchBooksByScannedIsbn", sender: searchQueryWithIsbn)
        
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "DELETE") { action, targetView, completionHandler in
            self.scannedIsbns.remove(at: indexPath.row)
            self.isbnsTableView.deleteRows(at: [indexPath], with: .fade)
            if self.scannedIsbns.count <= 0 {
                self.clearIsbnsBtn.isHidden = true
            }
        }
        
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
}

extension ScanBarcodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            if let verifyIsbnVC = storyboard?.instantiateViewController(withIdentifier: "verifyIsbnScan") as? VerifyIsbnViewController {
                verifyIsbnVC.modalPresentationStyle = .fullScreen
                verifyIsbnVC.configureVC(image: image)
                verifyIsbnVC.storeIsbn = { isbn in
                    if !self.scannedIsbns.contains(isbn) && !isbn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.scannedIsbns.append(isbn.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            
                present(verifyIsbnVC, animated: true, completion: nil)
                
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}
