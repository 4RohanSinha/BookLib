//
//  BookNoteViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 10/2/21.
//

import UIKit
import CoreData

class BookNoteViewController: CoreDataStackViewController {
    
    //IBOutlets to input views
    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var themesCollectionView: UICollectionView!
    @IBOutlet weak var quickThoughtItemArrayTableView: UITableView!
    @IBOutlet weak var noteTypeTitleLbl: UILabel!
    @IBOutlet weak var welcomeMessageLbl: UILabel!
    @IBOutlet weak var themeWelcomeMessage: UILabel!
    @IBOutlet weak var scanBtn: UIButton!
    
    //coredata entity objects
    var book: Book?
    var bookNote: BookNote?
    
    //cache the scanned notes in memory so that loading them into image view is easier
    private let cacheOfScannedNotes = NSCache<NSNumber, UIImage>()
    
    //used for themes collection view at the top
    var themesFetchedResultsController: NSFetchedResultsController<BookTheme>?
    var blockOperationsForThemesCollectionView: [BlockOperation] = []
    var quickThoughtArrayFetchedResultsController: NSFetchedResultsController<BookNoteQuickThoughtArrayItem>?
    
    //use to automatically scroll to most recently inserted note
    var scrollToEndAfterInsert = false
    var newIndexPathToScrollToAfterInsert: IndexPath?
    
    //use to move view up if the keyboard covers the editing text field or text view
    var textViewTextFieldFirstResponder: UIView?
    var keyboardMoved: Bool?
    
    func configureVC() {
        
        noteTypeTitleLbl.text = "Quick Thoughts" //type of note is a Quick Thought
        
        //set delegates + reload data for the collection view of book themes
        themesCollectionView.dataSource = self
        themesCollectionView.delegate = self
        
        
        //configure table view of quick thought array items, which make up a quick thought
        quickThoughtItemArrayTableView.isHidden = false
        quickThoughtItemArrayTableView.delegate = self
        quickThoughtItemArrayTableView.dataSource = self
        quickThoughtItemArrayTableView.separatorStyle = .none
        
        //configure view with book note data
        if let bookQuickThought = bookNote as? BookNoteQuickThought {

            noteTitle.text = bookQuickThought.itemTitle //set title of VC to note
            noteTitle.clearButtonMode = .whileEditing //while editing the note title, show the clear button
            noteTitle.delegate = self //set delegate to self - this allows the VC to save the text field when its contents are updated
        }
        
        //gesture recognizer to hide the keyboard and end editing of a textview or textfield
        //keyboard can be dismissed by tapping anywhere else in the view
        let hideGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideEditingView))
        hideGestureRecognizer.delegate = self
        view.addGestureRecognizer(hideGestureRecognizer)
    }
    
    //configure view
    func updateUI() {
        
        
        if quickThoughtArrayFetchedResultsController?.fetchedObjects?.count == 0 {
            welcomeMessageLbl.isHidden = false
        } else {
            welcomeMessageLbl.isHidden = true
        }
        
        if themesFetchedResultsController?.fetchedObjects?.count == 0 {
            themeWelcomeMessage.isHidden = false
        } else {
            themeWelcomeMessage.isHidden = true
        }
        
    }
    
    //fetched results controller of Themes
    func configureThemesFetchedResultsController() {
        guard let dataController = dataController, let bookNote = bookNote else { return }
        
        //configure fetch request of themes for the note - predicate should filter for themes that are associated with a particular note through a Core Data relationship
        let themesFetchRequest: NSFetchRequest<BookTheme> = BookTheme.fetchRequest()
        themesFetchRequest.predicate = NSPredicate(format: "%@ in notes", bookNote)
        themesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "themeId", ascending: true)]
        
        //configure fetched results controller - set delegate to self
        themesFetchedResultsController = NSFetchedResultsController(fetchRequest: themesFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        themesFetchedResultsController?.delegate = self
        
        do {
            try themesFetchedResultsController?.performFetch()
        } catch {
            alert(title: "Error", msg: "Unable to fetch themes associated with note.")
        }
    }
    
    func configureQuickThoughtArrayFetchedResultsController() {
        guard let dataController = dataController, let bookQuickThought = bookNote as? BookNoteQuickThought else { return }
        
        //configure fetch request to obtain contents of the quick thought
        let quickThoughtArrayFetchRequest = BookNoteQuickThoughtArrayItem.fetchRequest()
        quickThoughtArrayFetchRequest.predicate = NSPredicate(format: "quickThought = %@", bookQuickThought)
        quickThoughtArrayFetchRequest.sortDescriptors = [NSSortDescriptor(key: "quickThoughtId", ascending: true)]
        
        //configure fetched results controller
        quickThoughtArrayFetchedResultsController = NSFetchedResultsController(fetchRequest: quickThoughtArrayFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        quickThoughtArrayFetchedResultsController?.delegate = self
        do {
            try quickThoughtArrayFetchedResultsController?.performFetch()
        } catch {
            alert(title: "Error", msg: "Unable to fetch note contents")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureVC()
        updateUI()
        
        scanBtn.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addKeyboardNotifications() //move the keyboard if it covers textview
        
        //configure fetched results controller
        configureQuickThoughtArrayFetchedResultsController()
        configureThemesFetchedResultsController()
        
        updateUI()
        
        
        themesCollectionView.reloadData()
        
        
        quickThoughtItemArrayTableView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeKeyboardNotifications() //remove keyboard notifications
        
        //nullify themes fetched results controller's delegate
        themesFetchedResultsController?.delegate = nil
        
        //cancel all operations modifying the collection view
        for blockOperation in blockOperationsForThemesCollectionView {
            blockOperation.cancel()
        }
        
        //remove the cancelled operations altogether
        blockOperationsForThemesCollectionView.removeAll(keepingCapacity: false)
        
        //nullify themes fetched results controller itself
        themesFetchedResultsController = nil
        
        //reload collection view - it should be empty
        themesCollectionView.reloadData()
        
        //nullify quick thought array fetched results controller for note contents
        quickThoughtArrayFetchedResultsController?.delegate = nil
        quickThoughtArrayFetchedResultsController = nil
        
        //reload table view - it should be empty
        quickThoughtItemArrayTableView.reloadData()
        
        //empty cache
        cacheOfScannedNotes.removeAllObjects()
    }
    
    
    //button press to add a theme - segue to VC which allows for edits to the note's theme
    @IBAction func addTheme(_ sender: Any) {
        //check if value exists if a VC is instantiated, and for the dataController, book, + quickThought
        guard let quickThoughtThemesVC = storyboard?.instantiateViewController(withIdentifier: "bookNoteQuickThoughtThemesVC") as? QuickThoughtThemesViewController, let dataController = dataController, let book = book, let quickThought = bookNote as? BookNoteQuickThought else { return }
        
        //configure VC with values from above
        quickThoughtThemesVC.configureVC(dataController: dataController, note: quickThought, book: book)
        
        //show configured VC
        navigationController?.pushViewController(quickThoughtThemesVC, animated: true)
    }
    
    //add a quick thought to the note
    @IBAction func onCreateQuickThoughtArrayItem_btnTap(_ sender: Any) {
        //present pop up to ask the user about the type of content/information they want to add to the note - a scanned note or a typed out note
        let scanTypeAlertController = UIAlertController(title: "Type\(UIImagePickerController.isSourceTypeAvailable(.camera) ? " or Scan Quick Thought" : " Quick Thought")?", message: nil, preferredStyle: .actionSheet)
        
        //three options: scan, type, or cancel this operation
        let scanAction = UIAlertAction(title: "Scan", style: .default, handler: onScan_btnTap(action:))
        let typeAction = UIAlertAction(title: "Type", style: .default, handler: onType_btnTap(action:))
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        //add action to alert pop up
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            scanTypeAlertController.addAction(scanAction)
        }
        scanTypeAlertController.addAction(typeAction)
        scanTypeAlertController.addAction(cancelAction)
        
        //present pop up
        present(scanTypeAlertController, animated: true, completion: nil)
    }
    
    //present camera scanner
    func presentCameraScanner() {
        let cameraImagePicker = UIImagePickerController()
        cameraImagePicker.sourceType = .camera
        cameraImagePicker.delegate = self
        present(cameraImagePicker, animated: true, completion: nil)
    }
    
    @IBAction func onScanQuickThoughtArrayItem_btnTap(_ sender: Any) {
        presentCameraScanner()
    }
    
    func onScan_btnTap(action: UIAlertAction) {
        presentCameraScanner()
    }
    
    //if the user wants to type a new quick thought
    func onType_btnTap(action: UIAlertAction) {
        guard let dataController = dataController, let bookQuickThought = bookNote as? BookNoteQuickThought else { return }
        
        //create new quick thought array item
        //due to the fetched results controller, a new cell should automatically populate in the table view
        let newQuickThoughtArrayItem = BookNoteQuickThoughtArrayItem(context: dataController.viewContext)
        newQuickThoughtArrayItem.typedText = ""
        newQuickThoughtArrayItem.quickThoughtId = Int32(bookQuickThought.nextQuickThoughtId)
        newQuickThoughtArrayItem.quickThought = bookQuickThought
        try? dataController.viewContext.save()
    }
    
    //asynchronously convert Data to UIImage
    //scanned UIImages are stored as binary Data objects in Core Data
    //converting Data to UIImage can be time-consuming and shouldn't be called every time the table view cell loads
    //convert data to uiimage asynchronously, and then reconfigure corresponding table view cell when the operation's complete
    func convertDataToImage(index: NSNumber, data: Data, completion: @escaping (Bool, NSNumber, UIImage?) -> Void) {
        let convertQueue = DispatchQueue(label: "convertDataToImage")
        
        convertQueue.async {
            if let image = UIImage(data: data) {
                completion(true, index, image)
            } else {
                completion(false, index, nil)
            }
        }
    }
    
    //completion handler - repopulate table view
    func handleImageConversion(success: Bool, index: NSNumber, image: UIImage?) {
        if let image = image, success {
            self.cacheOfScannedNotes.setObject(image, forKey: index)
            DispatchQueue.main.async {
                self.quickThoughtItemArrayTableView.reloadData()
            }
        }
    }
    
    //hideEditingView - dismiss current text view or text field - resign first responder
    @objc func hideEditingView() {
        textViewTextFieldFirstResponder?.resignFirstResponder()
    }

}

//collection view delegate for themes collection view
extension BookNoteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return themesFetchedResultsController?.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themesFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "noteVCThemeCell", for: indexPath) as? BookNoteThemeCollectionViewCell else { return UICollectionViewCell() }
        guard let theme = self.themesFetchedResultsController?.object(at: indexPath), let bookNote = self.bookNote else { return UICollectionViewCell() }
        
        //cancel handler - when X is tapped, delete the current theme
        cell.cancelHandler = {
            //confirmation - alert handler
            let alertVC = UIAlertController(title: "Confirm", message: "Are you sure you want to remove the theme \(theme.title ?? "Untitled") from the note?", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { action in
                theme.removeFromNotes(bookNote)
                do {
                    try self.dataController?.viewContext.save()
                } catch {
                    self.alert(title: "Error", msg: "Unable to delete theme")
                }
            }))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        }
        
        //configure theme label
        cell.themeLbl.text = theme.title
        
        return cell
    }
    
    //if theme is tapped, open a detail VC that includes ALL notes associated with the theme
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let theme = themesFetchedResultsController?.object(at:indexPath) else { return }
        
        guard let themeVC = storyboard?.instantiateViewController(withIdentifier: "bookNotesFolderViewController") as? ReadingListBookNotesListViewController  else { return }
        
        themeVC.dataController = dataController
        themeVC.book = book
        themeVC.filteredBookTheme = theme
        
        navigationController?.pushViewController(themeVC, animated: true)
        
    }
    
    
}

//table view delegate for the array items in each book note/quick thought
extension BookNoteViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return quickThoughtArrayFetchedResultsController?.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quickThoughtArrayFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard bookNote != nil else { return UITableViewCell() }
        
        guard let currentQuickThoughtArrayItem = quickThoughtArrayFetchedResultsController?.object(at: indexPath) else { return UITableViewCell() }
        
        //there are two different prototype cells - one for typed quick thoughts, and the other for scanned quick thoughts
        if currentQuickThoughtArrayItem.type == .typed {
            //dequeue the typed prototype cell
            guard let typedQuickThoughtCell = quickThoughtItemArrayTableView.dequeueReusableCell(withIdentifier: "bookNoteViewTypedQuickThoughtCell", for: indexPath) as? BookNoteViewTypedQuickThoughtTableCell, let quickThoughtCellTextView = typedQuickThoughtCell.typedOutThoughtTextView as? BookNoteQuickThoughtArrayItemTextView else { return UITableViewCell() }
            
            //UI configuration
            typedQuickThoughtCell.selectionStyle = .none
            
            //textview should have typed text included
            quickThoughtCellTextView.text = quickThoughtArrayFetchedResultsController?.object(at: indexPath).typedText
            quickThoughtCellTextView.indexPathInQuickThoughtTable = indexPath
            quickThoughtCellTextView.delegate = self
            
            //if array item is empty, add placeholder
            if quickThoughtCellTextView.text.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                quickThoughtCellTextView.hasPlaceholder = true
            }
            
            //return cell
            return typedQuickThoughtCell
            
        } else if currentQuickThoughtArrayItem.type == .scanned {
            //dequeue scanned prototype cell
            guard let scannedQuickThoughtCell = quickThoughtItemArrayTableView.dequeueReusableCell(withIdentifier: "bookNoteViewScannedQuickThoughtCell", for: indexPath) as? BookNoteViewScannedQuickThoughtTableCell, let imageData = quickThoughtArrayFetchedResultsController?.object(at: indexPath).scannedPhotoData else { return UITableViewCell() }

            if let cellImage = cacheOfScannedNotes.object(forKey: NSNumber(value: indexPath.row)) { //if the scanned image has been stored into cache, configure cell this way
                scannedQuickThoughtCell.loadingImage = false
                scannedQuickThoughtCell.scannedThoughtImageView.image = cellImage
            } else { //if not loaded into cache, convert the data to a uiimage to put into the cache
                scannedQuickThoughtCell.loadingImage = true
                convertDataToImage(index: NSNumber(value: indexPath.row), data: imageData, completion: handleImageConversion(success:index:image:))
            }
            
            return scannedQuickThoughtCell
        }
        
        return UITableViewCell()
    }
    
    
    //if a scanned item is tapped, a VC should pop up that allows for editing
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //guard let - check if current note is nil, if the tapped array item is nil, if the tapped array item was scanned, and if the VC is nil
        guard let currentQuickThought = bookNote as? BookNoteQuickThought, let currentQuickThoughtArrayItem = quickThoughtArrayFetchedResultsController?.object(at: indexPath), currentQuickThoughtArrayItem.type == .scanned, let scannedQuickThoughtArrayItemVC = storyboard?.instantiateViewController(withIdentifier: "bookNoteScannedQuickThoughtArrayItemVC") as? BookNoteScannedQuickThoughtArrayItemViewController else { return }
        
        //configure VC with appropriate variables
        scannedQuickThoughtArrayItemVC.quickThought = currentQuickThought
        scannedQuickThoughtArrayItemVC.quickThoughtArrayItem = currentQuickThoughtArrayItem
        
        //show VC
        navigationController?.pushViewController(scannedQuickThoughtArrayItemVC, animated: true)
        
    }
    
    //allow for delete with swiping
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "DELETE") { action, targetView, completionHandler in
            guard let objToDelete = self.quickThoughtArrayFetchedResultsController?.object(at: indexPath) else {
                completionHandler(false)
                return
            }
            
            //confirmation
            let alertVC = UIAlertController(title: "Warning", message: "Are you sure you want to delete the quick thought? This action can't be undone.", preferredStyle: .alert)
            
            //delete - completion handler: delete the cell item + save + call completion handler
            alertVC.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { alertAction in
                self.dataController?.viewContext.delete(objToDelete)
                do {
                    try self.dataController?.viewContext.save()
                    completionHandler(true)
                } catch {
                    completionHandler(false)
                }
            }))
            
            //cancel the operation
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { alertAction in
                completionHandler(false)
            }))
            
            //present alert VC
            self.present(alertVC, animated: true, completion: nil)
        }
        
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
}

//MARK: keyboard functions
extension BookNoteViewController {
    
    //get info on the keyboard
    func getKeyboardFrame(_ notification: Notification) -> CGRect {
        let info = notification.userInfo!
        return (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        return getKeyboardFrame(notification).height
    }
    
    func addKeyboardNotifications() {
        //add observers of keyboard when view appears
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardNotifications() {
        //remove observers of keyboard when view disappears
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        //get keyboard height & frame
        let keyboardHeight = getKeyboardHeight(notification)
        let keyboardFrame = getKeyboardFrame(notification)
        
        //get active text view or text field
        //get the view's frame
        //convert the coordinates of the frame to the global view's coordinates, since the frame might be located in a nested view
        if let activeTextViewField = textViewTextFieldFirstResponder, let activeFrame = activeTextViewField.superview?.convert(activeTextViewField.bounds, to: nil) {
            //if the keyboard frame covers the frame of the text field entirely, or just part of it
            if (keyboardFrame.contains(activeFrame) || keyboardFrame.minY < activeFrame.maxY) {
                keyboardMoved = true
                view.frame.origin.y = -keyboardHeight
            //if the keyboard does not cover the frame of the text field entirely, but the view was previously moved to accommodate a different text field
            } else if (activeFrame.minY+keyboardHeight) < keyboardFrame.minY && keyboardMoved == true {
                keyboardMoved = false
                view.frame.origin.y += keyboardHeight
            //if the view did not move
            } else if keyboardMoved == nil {
                keyboardMoved = false
            }
        }
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        //if the view was moved up, move it back down
        if keyboardMoved == true {
            let keyboardHeight = getKeyboardHeight(notification)
            view.frame.origin.y += keyboardHeight
        }
        
        keyboardMoved = nil
    }
}

extension BookNoteViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return textViewTextFieldFirstResponder?.isFirstResponder == true
    }
}

extension BookNoteViewController: UITextFieldDelegate {
    
    //set currently editing textfield
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textViewTextFieldFirstResponder = textField
    }
    
    //nullify currently editing text field when editing
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textViewTextFieldFirstResponder == textField {
            textViewTextFieldFirstResponder = nil
        }
    }
    
    //when editing of title text field stops
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //save note
        if textField == noteTitle {
            
            if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                textField.text = "Untitled note"
            }
            
            noteTitle.text = textField.text
            bookNote?.itemTitle = textField.text
            
            
            
            try? dataController?.viewContext.save()
        }
        
        textField.resignFirstResponder()
        return true
    }
}

extension BookNoteViewController: UITextViewDelegate {
    
    //set currently editing textview
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textViewTextFieldFirstResponder = textView
        return true
    }
    
    //nullify currently editing textview when editing
    func textViewDidBeginEditing(_ textView: UITextView) {
        if let textView = textView as? BookNoteQuickThoughtArrayItemTextView {
            textView.removePlaceholder()
        }
    }
    
    //save text every time text view changes
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if let textView = textView as? BookNoteQuickThoughtArrayItemTextView, let indexPath = textView.indexPathInQuickThoughtTable, let newTypedText = textView.text {
                
                quickThoughtArrayFetchedResultsController?.object(at: indexPath).typedText = newTypedText
                try? dataController?.viewContext.save()
            }
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    //editing stops - nullify text view
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        
        if textViewTextFieldFirstResponder == textView {
            textViewTextFieldFirstResponder = nil
        }
        
        return true
    }
    
    //after editing stopped, set placeholder if text is blank
    func textViewDidEndEditing(_ textView: UITextView) {
        if let textView = textView as? BookNoteQuickThoughtArrayItemTextView, let newTypedText = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if newTypedText == "" {
                textView.hasPlaceholder = true
            }
        }
    }
}

extension BookNoteViewController: NSFetchedResultsControllerDelegate {
    //call beginUpdates for table view
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == quickThoughtArrayFetchedResultsController {
            quickThoughtItemArrayTableView.beginUpdates()
        }
    }
    
    //after changes to content end
    //for a table view, call endUpdates. also - if a new cell is added, scroll to the end for it to be visible
    //for a collection view, execute all the updates stored in blockOperations
    //this function is necessary to ensure consistency between the table view and the data
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == quickThoughtArrayFetchedResultsController {
            quickThoughtItemArrayTableView.endUpdates() //end table view updates
            
            if let newIndexPathToScrollTo = newIndexPathToScrollToAfterInsert, scrollToEndAfterInsert {
                scrollToEndAfterInsert = false //set to false to prevent this from occurring repeatedly
                
                //scroll
                quickThoughtItemArrayTableView.scrollToRow(at: newIndexPathToScrollTo, at: .top, animated: true)
                
                //set placeholder
                if let newQuickThoughtCell = quickThoughtItemArrayTableView.cellForRow(at: newIndexPathToScrollTo) as? BookNoteViewTypedQuickThoughtTableCell, let quickThoughtTextView = newQuickThoughtCell.typedOutThoughtTextView as? BookNoteQuickThoughtArrayItemTextView {
                    quickThoughtTextView.hasPlaceholder = true
                }
                
            }
            
        }  else if controller == themesFetchedResultsController {
            //performBatchUpdates - update collection view
            themesCollectionView.performBatchUpdates {
                for blockOperation in blockOperationsForThemesCollectionView {
                    blockOperation.start()
                }
            } completion: { finished in
                //remove all block operations since they're done
                self.blockOperationsForThemesCollectionView.removeAll(keepingCapacity: false)
            }
        }
        
        updateUI()

    }
    
    //every time a new item inserted
    //table view - insert, delete, reload, or move a row
    //collection view - same as table view, except embed in a block operation to be executed after all changes to content are made
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if controller == quickThoughtArrayFetchedResultsController {
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    quickThoughtItemArrayTableView.insertRows(at: [newIndexPath], with: .fade)
                    scrollToEndAfterInsert = true
                    newIndexPathToScrollToAfterInsert = newIndexPath
                }
            case .delete:
                if let indexPath = indexPath {
                    quickThoughtItemArrayTableView.deleteRows(at: [indexPath], with: .fade)
                }
            case .update:
                if let indexPath = indexPath {
                    quickThoughtItemArrayTableView.reloadRows(at: [indexPath], with: .fade)
                }
            case .move:
                if let indexPath = indexPath, let newIndexPath = newIndexPath {
                    quickThoughtItemArrayTableView.moveRow(at: indexPath, to: newIndexPath)
                }
            default: break
            }
        } else if controller == themesFetchedResultsController {
            switch type {
            case .insert:
                blockOperationsForThemesCollectionView.append(BlockOperation(block: {
                    self.themesCollectionView.insertItems(at: [newIndexPath!])
                }))
            case .delete:
                blockOperationsForThemesCollectionView.append(BlockOperation(block: {
                    self.themesCollectionView.deleteItems(at: [indexPath!])
                }))
            case .move:
                blockOperationsForThemesCollectionView.append(BlockOperation(block: {
                    self.themesCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
                }))
            case .update:
                blockOperationsForThemesCollectionView.append(BlockOperation(block: {
                    self.themesCollectionView.reloadItems(at: [indexPath!])
                }))
            default: break
            }
        }
    }
    
    //if a new section is added, deleted, or moved
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        if controller == quickThoughtArrayFetchedResultsController {
            switch type {
            case .insert:
                quickThoughtItemArrayTableView.insertSections(indexSet, with: .fade)
            case .delete:
                quickThoughtItemArrayTableView.deleteSections(indexSet, with: .fade)
            case .move, .update:
                break
            default:
                break
            }
        } else if controller == themesFetchedResultsController {
            switch type {
            case .insert:
                themesCollectionView.insertSections(indexSet)
            case .delete:
                themesCollectionView.deleteSections(indexSet)
            case .move, .update:
                break
            default:
                break
            }
        }
    }
}

//image picker delegate
extension BookNoteViewController: UINavigationControllerDelegate,  UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage, let imageData = image.pngData() {
            guard let dataController = dataController, let bookQuickThought = bookNote as? BookNoteQuickThought else { return }
            
            //store image in new quick thought item
            let newQuickThoughtArrayItem = BookNoteQuickThoughtArrayItem(context: dataController.viewContext)
            newQuickThoughtArrayItem.quickThoughtId = Int32(bookQuickThought.nextQuickThoughtId)
            newQuickThoughtArrayItem.quickThought = bookQuickThought
            newQuickThoughtArrayItem.scannedPhotoData = imageData
            try? dataController.viewContext.save()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
