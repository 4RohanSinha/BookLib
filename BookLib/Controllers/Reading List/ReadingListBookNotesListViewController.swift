//
//  ReadingListBookNotesListViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 9/6/21.
//

import UIKit
import CoreData

//TODO: preview of folder items
class ReadingListBookNotesListViewController: CoreDataStackViewController {

    //IBOutlets
    @IBOutlet weak var folderContentsTableView: UITableView!
    @IBOutlet weak var folderTitleTextField: UITextField!
    @IBOutlet weak var itemSearchView: UISearchBar!
    @IBOutlet weak var welcomeMessage: UILabel!
    @IBOutlet weak var noResultsAvailableLbl: UILabel!
    @IBOutlet weak var newFolderBtn: UIBarButtonItem!
    @IBOutlet weak var deleteThemeOrFolderBtn: UIButton!
    
    var book: Book?
    var currentFolder: BookNoteFolder?
    var folderItemsFetchedResultsController: NSFetchedResultsController<BookNoteFolderItem>?
    
    var filteredBookTheme: BookTheme?
    
    //this predicate always stays the same
    //when a user searches for a note, the predicate used for the fetched results controller changes
    //regardless, the base predicate stays the same
    //it filters for notes related to this book & folder/theme
    var baseFilterPredicate: NSPredicate?
    
    func configureView() {
        //configure VC for folder or theme
        //if folder is not nil, configure VC according to folder attributes
        //if theme is not nil, configure VC according to theme's attributes instead
        if let currentFolder = currentFolder {
            folderTitleTextField.text = currentFolder.itemTitle
            folderTitleTextField.placeholder = "Untitled folder"
            folderTitleTextField.clearButtonMode = .whileEditing
            folderTitleTextField.delegate = self
            
        } else if let filteredBookTheme = filteredBookTheme {
            folderTitleTextField.text = "\(filteredBookTheme.title ?? "Untitled theme")"
            folderTitleTextField.placeholder = "Untitled theme"
            folderTitleTextField.clearButtonMode = .whileEditing
            folderTitleTextField.delegate = self
            newFolderBtn.isEnabled = false
            newFolderBtn.tintColor = UIColor.clear
            deleteThemeOrFolderBtn.isHidden = false
            
        } else {
            folderTitleTextField.text = "My Notes"
            folderTitleTextField.isEnabled = false
            deleteThemeOrFolderBtn.isHidden = true
        }
    }
    
    func configureFetchedResultsController() {
        guard let dataController = dataController, let book = book else { return }
        
        //create fetch request and sort items by creation date
        let notesFetchRequest: NSFetchRequest<BookNoteFolderItem> = BookNoteFolderItem.fetchRequest()
        notesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        //create predicate
        if let bookTheme = filteredBookTheme {
            //filter all notes associated with the theme
            notesFetchRequest.predicate = NSPredicate(format: "typeIdentifier = 1 AND ANY themes = %@", bookTheme)
        } else if let currentFolder = currentFolder {
            //filter all notes located inside the folder
            notesFetchRequest.predicate = NSPredicate(format: "book == %@ AND itemParent == %@", book, currentFolder)
        } else {
            notesFetchRequest.predicate = NSPredicate(format: "book == %@ AND itemParent == NIL", book)
        }
        
        baseFilterPredicate = notesFetchRequest.predicate
        
        
        folderItemsFetchedResultsController = NSFetchedResultsController(fetchRequest: notesFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        folderItemsFetchedResultsController?.delegate = self

        do {
            try folderItemsFetchedResultsController?.performFetch()
        } catch {
            alert(title: "Error", msg: "Unable to fetch notes")
        }
        
    }
    
    func deinitFetchedResultsController() {
        folderItemsFetchedResultsController?.delegate = nil
        folderItemsFetchedResultsController = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureFetchedResultsController() //configure fetched results controller of book folder items
        configureView() //configure view depending on folder or theme
        folderContentsTableView.reloadData() //reload data in the table view
        
        //welcome message should be hidden only if there are items in this folder/theme
        if folderItemsFetchedResultsController?.sections?[0].numberOfObjects == 0 {
            welcomeMessage.isHidden = false
        } else {
            welcomeMessage.isHidden = true
        }
        
        //no results label should be hidden
        noResultsAvailableLbl.isHidden = true
        
        //perform search if there is text in the search bar
        if itemSearchView.text != "" && itemSearchView.text != nil {
            performSearch(searchBar: itemSearchView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //deinitialize fetched results controller to nil
        deinitFetchedResultsController()
        folderContentsTableView.reloadData()
        noResultsAvailableLbl.isHidden = true //hide no results label
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemSearchView.delegate = self
        folderContentsTableView.separatorStyle = .none
        folderContentsTableView.delegate = self
        folderContentsTableView.dataSource = self
        
        //when user taps somewhere outside the keyboard, keyboard + search bar should be dismissed
        let dismissSearchInputViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissSearchBar))
        dismissSearchInputViewGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissSearchInputViewGestureRecognizer)
        
    }
    
    @IBAction func createNewFolder(_ sender: Any) {
        guard let dataController = dataController else { return }
        let alertVC = UIAlertController(title: "New Folder", message: "Enter the name of the new folder: ", preferredStyle: .alert)
        alertVC.addTextField { textfield in
            textfield.placeholder = "Name of folder"
        }
        
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            
            //create folder
            let textfield = alertVC.textFields?[0] //text field
            
            //create moc object
            let newFolder = BookNoteFolder(context: dataController.viewContext)
            newFolder.book = self.book
            newFolder.itemTitle = textfield?.text ?? "Untitled folder"
            
            //if empty - title = "Untitled folder"
            if textfield?.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                newFolder.itemTitle = "Untitled folder"
            }
            
            if let currentFolder = self.currentFolder {
                newFolder.itemParent = currentFolder
            }
            
            do {
                try dataController.viewContext.save()
            } catch {
                self.alert(title: "Error", msg: "Unable to add new folder")
            }
        }))
        
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertVC, animated: true, completion: nil)
    }
    
    
    @IBAction func createNewQuickThought(_ sender: Any) {
        guard let dataController = dataController else { return }
        
        let alertVC = UIAlertController(title: "New Quick Thought", message: "Enter the name of the new quick thought note: ", preferredStyle: .alert)
        
        alertVC.addTextField { textfield in
            textfield.placeholder = "Name of note"
        }
        
        //MARK: similar as above - ask user to name folder
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            let textfield = alertVC.textFields?[0]
            let newNote = BookNoteQuickThought(context: dataController.viewContext)
            newNote.book = self.book
            newNote.itemTitle = textfield?.text ?? "Untitled note"
            
            if textfield?.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                newNote.itemTitle = "Untitled note"
            }
            
            if let currentFolder = self.currentFolder {
                newNote.itemParent = currentFolder
            }
            
            if let bookTheme = self.filteredBookTheme {
                newNote.addToThemes(bookTheme)
            }
            
            do {
                try dataController.viewContext.save()
            } catch {
                self.alert(title: "Error", msg: "Unable to add new note")
            }
        }))
        
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
    
    //delete
    @IBAction func deleteThemeBtn(_ sender: Any) {
        guard let objToDelete = self.filteredBookTheme ?? self.currentFolder else {
            return
        }
        
        //MARK: create message for UIAlertController
        var descriptor = ""
        var warning = ""
        
        if let themeToDelete = objToDelete as? BookTheme { //if this VC is being used to display a theme's notes
            descriptor = "theme \(themeToDelete.title ?? "Untitled")"
            warning = " Notes associated with the theme will NOT be deleted."
        } else if let folderToDelete = objToDelete as? BookNoteFolder { //if this VC is being used to display a folder's notes
            descriptor = "folder \(folderToDelete.itemTitle ?? "Untitled")"
            warning = " Notes inside the folder WILL be deleted."
        } else {
            descriptor = "unknown object"
        }
        
        let alertVC = UIAlertController(title: "Warning", message: "Are you sure you want to delete the \(descriptor)? This action can't be undone.\(warning)", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { alertAction in
            self.navigationController?.popViewController(animated: true)
            
            self.dataController?.viewContext.delete(objToDelete)
            try? self.dataController?.viewContext.save()
        }))
        
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }

}

extension ReadingListBookNotesListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return itemSearchView.isFirstResponder || folderTitleTextField.isFirstResponder //if the folder's title or the search bar is being edited, the gesture recognizer SHOULD receive touch
    }
}

extension ReadingListBookNotesListViewController: UISearchBarDelegate {
    func performSearch(searchBar: UISearchBar) {
        guard let baseFilterPredicate = baseFilterPredicate else { return }
        
        guard welcomeMessage.isHidden else { return }
        
        guard let searchQuery = searchBar.text else { return }
        
        noResultsAvailableLbl.isHidden = true
        
        //reset predicate if the search bar is empty
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            folderItemsFetchedResultsController?.fetchRequest.predicate = baseFilterPredicate
            try? folderItemsFetchedResultsController?.performFetch()
            folderContentsTableView.reloadData()
            return
        }
        
        //search query - NSPredicate looking for folder items or themes with titles similar to the search query
        let searchPredicateItemTitles: NSPredicate = NSPredicate(format: "itemTitle LIKE[c] %@", "*\(searchQuery)*")
        let searchPredicateThemes: NSPredicate = NSPredicate(format: "ANY themes.title LIKE[c] %@", "*\(searchQuery)*")
        
        //combine the two predicates above with an OR condition
        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [searchPredicateItemTitles, searchPredicateThemes])
        
        //combine the search predicate + the base predicate (filtering for notes in the folder or theme)
        let combinedSearchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [baseFilterPredicate, searchPredicate])
        
        //reassign the predicate of the fetched results controller
        folderItemsFetchedResultsController?.fetchRequest.predicate = combinedSearchPredicate
        try? folderItemsFetchedResultsController?.performFetch()
        folderContentsTableView.reloadData()
        
        if folderItemsFetchedResultsController?.fetchedObjects?.count == 0 {
            noResultsAvailableLbl.isHidden = false //if no results are available, show the label
        }
    }
    
    //perform search when the text changes
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(searchBar: searchBar)
    }
    
    //when search button is tapped, dismiss keyboard
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        performSearch(searchBar: searchBar)
        
    }
    
    //cancel - return to original predicate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        folderItemsFetchedResultsController?.fetchRequest.predicate = baseFilterPredicate
        itemSearchView.resignFirstResponder()
    }
    
    //dismiss search bar + title text field when user taps anywhere else in the view
    @objc func dismissSearchBar() {
        
        if itemSearchView.isFirstResponder {
            itemSearchView.resignFirstResponder()
        }
        else if folderTitleTextField.isFirstResponder {
            folderTitleTextField.resignFirstResponder()
        }
    }
}

extension ReadingListBookNotesListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == folderTitleTextField {
            
            
            if let filteredBookTheme = filteredBookTheme {
                //if title is empty, name it "Untitled theme"
                if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                    textField.text = "Untitled theme"
                }
                
                filteredBookTheme.title = textField.text
                
            } else if let folder = currentFolder {
                //if folder is empty, name it "Untitled folder"
                if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                    textField.text = "Untitled folder"
                }
                
                folder.itemTitle = textField.text
            }
            do {
                try dataController?.viewContext.save()
            } catch {
                alert(title: "Error", msg: "Unable to save changes to title.")
            }
            
            folderContentsTableView.reloadData()
        }
        
        textField.resignFirstResponder()
        return true
    }
}

extension ReadingListBookNotesListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return folderItemsFetchedResultsController?.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderItemsFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let folderItem = folderItemsFetchedResultsController?.object(at: indexPath) else { return UITableViewCell() }
    
        
        if let folder = folderItem as? BookNoteFolder, let cell = tableView.dequeueReusableCell(withIdentifier: "noteFolderTableViewCell") as? BookNoteFolderTableViewCell {
            cell.selectionStyle = .none
            cell.folderNameLbl.text = folder.itemTitle
            return cell
        } else if let quickThought = folderItem as? BookNoteQuickThought, let cell = tableView.dequeueReusableCell(withIdentifier: "noteQuickThoughtTableViewCell") as? BookNoteQuickThoughtTableViewCell {
            
            //each table view cell row (a note) has a collection view of themes
            //it needs to be configured with an array of themes
            
            let bookNoteThemesDelegate = BookNoteThemesTableCollectionViewDelegate()
            bookNoteThemesDelegate.cellIdentifier = "themeCollectionViewCellForQuickThoughtTableViewCell"
            
            //provide array of themes for the delegate to populate the collection view
            if let bookNoteThemeSet = quickThought.themes as? Set<BookTheme> {
                let bookNoteThemeArr = Array(bookNoteThemeSet)
                bookNoteThemesDelegate.themes = bookNoteThemeArr.sorted { $0.themeId < $1.themeId }
            }
            
            
            cell.selectionStyle = .none
            cell.noteTitle.text = quickThought.itemTitle
            cell.themesCollectionViewDelegates = bookNoteThemesDelegate
            
            //when the theme is tapped, segue to another instance of this VC, filtered for notes of that particular theme
            cell.onThemeCellTapHandler = { indexPath in
                let selectedTheme = bookNoteThemesDelegate.themes[indexPath.row]
                guard selectedTheme != self.filteredBookTheme else { return }
                
                guard let themeVC = self.storyboard?.instantiateViewController(withIdentifier: "bookNotesFolderViewController") as? ReadingListBookNotesListViewController  else { return }
                themeVC.dataController = self.dataController
                themeVC.book = self.book
                themeVC.filteredBookTheme = selectedTheme
                
                self.navigationController?.pushViewController(themeVC, animated: true)
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    //if a folder is selected, segue to another instance of this VC with the notes for that particular folder
    //if a note is selected, segue to the BookNoteViewController
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let selectedFolder = folderItemsFetchedResultsController?.object(at: indexPath) as? BookNoteFolder {
        
            guard let bookNoteFolderVC = storyboard?.instantiateViewController(withIdentifier: "bookNotesFolderViewController") as? ReadingListBookNotesListViewController else { return }
            
            bookNoteFolderVC.book = book
            bookNoteFolderVC.dataController = dataController
            bookNoteFolderVC.currentFolder = selectedFolder
            
            navigationController?.pushViewController(bookNoteFolderVC, animated: true)
        } else if let selectedNote = folderItemsFetchedResultsController?.object(at: indexPath) as? BookNote {
            guard let bookNoteVC = storyboard?.instantiateViewController(withIdentifier: "bookNoteViewController") as? BookNoteViewController else { return }
            bookNoteVC.book = book
            bookNoteVC.bookNote = selectedNote
            navigationController?.pushViewController(bookNoteVC, animated: true)
            bookNoteVC.dataController = dataController
        }
    }
    
    //swipe to delete a folder or a note
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "DELETE") { action, targetView, completionHandler in
            guard let objToDelete = self.folderItemsFetchedResultsController?.object(at: indexPath) else {
                completionHandler(false)
                return
            }
            
            let alertVC = UIAlertController(title: "Warning", message: "Are you sure you want to delete the \(((objToDelete.typeIdentifier == 1) ? "note" : "folder")) \(objToDelete.itemTitle ?? "Untitled")? This action can't be undone.", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { alertAction in
                self.dataController?.viewContext.delete(objToDelete)
                do {
                    try self.dataController?.viewContext.save()
                    completionHandler(true)
                } catch {
                    completionHandler(false)
                }
            }))
            
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { alertAction in
                completionHandler(false)
            }))
            
            self.present(alertVC, animated: true, completion: nil)
        }
        
        deleteAction.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
}

extension ReadingListBookNotesListViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        folderContentsTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        folderContentsTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if folderItemsFetchedResultsController?.sections?[0].numberOfObjects == 0 {
            welcomeMessage.isHidden = false
        } else {
            welcomeMessage.isHidden = true
        }
        
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                folderContentsTableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                folderContentsTableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath {
                folderContentsTableView.reloadRows(at: [indexPath], with: .fade)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                folderContentsTableView.moveRow(at: indexPath, to: newIndexPath)
            }
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            folderContentsTableView.insertSections(indexSet, with: .fade)
        case .delete:
            folderContentsTableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            break
        default: break
        }
    }
}
