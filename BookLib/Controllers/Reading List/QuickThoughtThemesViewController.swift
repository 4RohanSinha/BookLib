//
//  QuickThoughtThemesViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 10/30/21.
//

import UIKit
import CoreData

class QuickThoughtThemesViewController: CoreDataStackViewController {

    var book: Book?
    var quickThought: BookNoteQuickThought?
    var themesFetchedResultsController: NSFetchedResultsController<BookTheme>?
    
    var editingContext: NSManagedObjectContext? //a child managed object context - child of the viewContext in the dataController. This is used a scratchpad to make temporary edits that can be rolled back.
    //the regular managed object context is not used here because it autosaves, so it would save any changes made every 30 seconds, even if the user did not want to commit them just yet
    
    var willSave: Bool = false //this boolean is used to determine whether all changes should be rolled back in viewWillDisappear
    
    //IB OUTLETS
    @IBOutlet weak var newThemeTextField: UITextField!
    @IBOutlet weak var themesTableView: UITableView!
    
    func configureFetchedResultsController() {
        guard let editingContext = editingContext, let book = book else { return }

        //create fetch request - find all themes associated with the book
        let themesFetchRequest = BookTheme.fetchRequest()
        themesFetchRequest.predicate = NSPredicate(format: "book = %@", book)
        themesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "themeId", ascending: true)]
        
        //fetched results controller - created on the child context, NOT the main view context, so that changes can be rolled back (see above)
        //if fetched results controller were created on the main view context, changes on the child context would not be seen until they are saved - but the point of this VC is to show temporary changes and allow the user to reverse them as they wish
        themesFetchedResultsController = NSFetchedResultsController(fetchRequest: themesFetchRequest, managedObjectContext: editingContext, sectionNameKeyPath: nil, cacheName: nil)
        themesFetchedResultsController?.delegate = self
        do {
            try themesFetchedResultsController?.performFetch()
        } catch {
            alert(title: "Error", msg: "Unable to fetch themes associated with the book.")
        }
    }
    
    func deinitFetchedResultsController() {
        themesFetchedResultsController?.delegate = nil
        themesFetchedResultsController = nil
    }
    
    //called in the previous VC
    //sets variables but also creates the child context, whose parent is the main view context in the DataControllerStack object passed around
    func configureVC(dataController: DataControllerStack, note: BookNoteQuickThought, book: Book) {
        self.dataController = dataController
        editingContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        editingContext?.parent = dataController.viewContext
        editingContext?.undoManager = UndoManager()
        
        //use object id to get the managed object for the child object
        self.book = editingContext?.object(with: book.objectID) as? Book
        self.quickThought = editingContext?.object(with: note.objectID) as? BookNoteQuickThought
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //if the changes will not be saved (the back button was pressed, not the save button)
        if !willSave {
            editingContext?.rollback()
            //rollback the changes, rather than merge them
            dataController?.viewContext.perform {
                self.dataController?.viewContext.rollback()
            }
        }
        
        deinitFetchedResultsController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        themesTableView.dataSource = self
        themesTableView.delegate = self
        themesTableView.separatorStyle = .none
        
        newThemeTextField.delegate = self
        
        //keyboard gesture recognizer - dismiss keyboard when user taps anywhere else on the view
        let hideKeyboardGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        hideKeyboardGestureRecognizer.delegate = self
        view.addGestureRecognizer(hideKeyboardGestureRecognizer)
    }
    
    //when theme is added, add to table view
    @IBAction func onAddTheme_btnTap(_ sender: Any) {
        guard let editingContext = editingContext, let book = book else { return }
                
        let newBookTheme = BookTheme(context: editingContext)
        newBookTheme.book = book
        newBookTheme.title = newThemeTextField.text
        
        if newThemeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            newBookTheme.title = "Untitled theme"
        }
        
        newBookTheme.themeId = self.themesFetchedResultsController?.fetchedObjects?.last?.themeId ?? -1
        
        newThemeTextField.text = ""
        newThemeTextField.resignFirstResponder()
    }
    
    @IBAction func onSaveThemes_btnTap(_ sender: Any) {
        //save changes
        //saving on the child context pushes the changes to the main view context
        //saving on the main view context pushes to the persistent store
        
        editingContext?.perform {
            do {
                try self.editingContext?.save()
            } catch {
                self.alert(title: "Error", msg: "Unable to save changes")
            }
        }
        
        dataController?.viewContext.perform {
            do {
                try self.dataController?.viewContext.save()
            } catch {
                self.alert(title: "Error", msg: "Unable to save changes")
            }
        }
        
        willSave = true
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onUndoButtonTap(_ sender: Any) {
        editingContext?.undo()
    }
    
    @IBAction func onRedoButtonTap(_ sender: Any) {
        editingContext?.redo()
    }
    
    
    @objc func dismissKeyboard() {
        newThemeTextField.resignFirstResponder()
    }
}

extension QuickThoughtThemesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return newThemeTextField.isFirstResponder //gesture recognizer only active if the user is editing the text field
    }
}

extension QuickThoughtThemesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return themesFetchedResultsController?.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themesFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookQuickThoughtAddThemeCell") as? BookQuickThoughtAddThemeCell, let theme = themesFetchedResultsController?.object(at: indexPath), let quickThought = quickThought else { return UITableViewCell() }
        
        cell.selectionStyle = .none
        
        //add handler - add theme when button tapped
        cell.addHandler = {
            quickThought.addToThemes(theme)
        }
        
        //delete handler - delete theme when button tapped
        cell.deleteHandler = {
            quickThought.removeFromThemes(theme)
        }
        
        //configure cell with theme + note
        cell.configureCell(theme: theme, note: quickThought)
        
        return cell
    }
}

extension QuickThoughtThemesViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        themesTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        themesTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                themesTableView.insertRows(at: [
                newIndexPath], with: .fade)

            }
        case .delete:
            if let indexPath = indexPath {
                themesTableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                themesTableView.moveRow(at: indexPath, to: newIndexPath)
            }
        case .update:
            if let indexPath = indexPath {
                themesTableView.reloadRows(at: [indexPath], with: .fade)
            }
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            themesTableView.insertSections(indexSet, with: .fade)
        case .delete:
            themesTableView.deleteSections(indexSet, with: .fade)
        case .move, .update:
            break
        default:
            break
        }
    }
}

extension QuickThoughtThemesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
