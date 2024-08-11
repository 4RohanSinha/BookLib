//
//  BookNoteScannedQuickThoughtArrayItemViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 10/9/21.
//

import UIKit

class BookNoteScannedQuickThoughtArrayItemViewController: CoreDataStackViewController {

    //scanned image view
    @IBOutlet weak var imageView: UIImageView!
    
    //buttons
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var uploadBtn: UIButton!
    
    //buttons created using uiviews + gesturerecognizers
    @IBOutlet weak var revertBtnView: UIViewRounded!
    @IBOutlet weak var saveBtnView: UIViewRounded!
    
    //button labels
    @IBOutlet weak var scanButtonLbl: UILabel!
    @IBOutlet weak var uploadPhotoLbl: UILabel!
    
    //user image guide label
    @IBOutlet weak var userImageGuideLbl: UILabel!
    
    //if image is edited
    var imageEdited: Bool = false
    
    //quickthought + current array item
    var quickThought: BookNoteQuickThought?
    var quickThoughtArrayItem: BookNoteQuickThoughtArrayItem?
    
    func configureButtons() {
        //revert + save buttons - connect to event handler (tap) functions
        let revertTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(revertImageToOriginal))
        let saveTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(saveQuickThoughtArrayItem))
        
        revertBtnView.addGestureRecognizer(revertTapGestureRecognizer)
        saveBtnView.addGestureRecognizer(saveTapGestureRecognizer)
        
    }
    
    func configureUI() {
        
        //hide buttons when ui is configured initially
        //buttons should only be visible if image has been edited
        revertBtnView.isHidden = true
        saveBtnView.isHidden = true
        
        guard let quickThoughtArrayItem = quickThoughtArrayItem else { return }
        
        //configure isHidden status of image guide label + configure imageview to contain image
        if let scannedImageData = quickThoughtArrayItem.scannedPhotoData {
            userImageGuideLbl.isHidden = true
            imageView.image = UIImage(data: scannedImageData)
        } else {
            userImageGuideLbl.isHidden = false
        }
    }
    
    //configure image edited status
    func configureImageEdited(status: Bool, withImage: UIImage?) {
        imageEdited = status
        revertBtnView.isHidden = !status
        saveBtnView.isHidden = !status
        imageView.image = withImage
    }
    
    //open camera to select photo
    @IBAction func openCameraForPhotoSelection() {
        let cameraImagePicker = UIImagePickerController()
        cameraImagePicker.sourceType = .camera
        cameraImagePicker.delegate = self
        present(cameraImagePicker, animated: true, completion: nil)

    }
    
    //open photo album to select photo
    @IBAction func openGalleryViewForPhotoSelection() {
        let cameraImagePicker = UIImagePickerController()
        cameraImagePicker.sourceType = .photoLibrary
        cameraImagePicker.delegate = self
        present(cameraImagePicker, animated: true, completion: nil)
    }
    
    //revert action - revert to image before edits
    @objc func revertImageToOriginal() {
        if let quickThoughtArrayItem = quickThoughtArrayItem, let scannedImageData = quickThoughtArrayItem.scannedPhotoData {
            configureImageEdited(status: false, withImage: UIImage(data: scannedImageData))
        }
    }
    
    //save - save updated image
    @objc func saveQuickThoughtArrayItem() {
        guard let quickThoughtArrayItem = quickThoughtArrayItem, let newScannedImageData = imageView.image?.pngData() else { return }
        quickThoughtArrayItem.scannedPhotoData = newScannedImageData
        try? dataController?.viewContext.save()
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI() //initially should not be visible
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtons()
        configureUI()
    }
    
}

//image picker - place image into uiimageview after selecting it
extension BookNoteScannedQuickThoughtArrayItemViewController: UINavigationControllerDelegate,  UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            dismiss(animated: true) {
                self.configureImageEdited(status: true, withImage: image)
            }
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
