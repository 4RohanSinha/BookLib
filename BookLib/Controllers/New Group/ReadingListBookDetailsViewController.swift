//
//  ReadingListBookDetailsViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/19/21.
//

import UIKit
import CoreData

class ReadingListBookDetailsViewController: CoreDataStackViewController {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var themesTableView: UITableView!
    @IBOutlet weak var themePageControl: UIPageControl!
    
    @IBOutlet weak var bookInformationTapView: UIViewRounded!
    @IBOutlet weak var notesTapView: UIViewRounded!
    
    var book: Book?
    var currentScrollingIndexPathForThemesTableViewIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    var bookThemesFetchedResultsController: NSFetchedResultsController<BookTheme>?
    var newRowToScrollTo: IndexPath?
    var themesTableViewGestRecognizer: UITapGestureRecognizer?
        
    func initFetchedResultsController() {
        guard let book = book, let dataController = dataController else { return }
        let bookThemesFetchRequest: NSFetchRequest<BookTheme> = BookTheme.fetchRequest()
        bookThemesFetchRequest.predicate = NSPredicate(format: "book == %@", book)
        bookThemesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "themeId", ascending: true)]
        bookThemesFetchedResultsController = NSFetchedResultsController(fetchRequest: bookThemesFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "themesForBookWithIsbn\(book.persistentBookInformation?.isbn13 ?? book.persistentBookInformation?.isbn10 ?? "Unknown")WithTitle\(book.persistentBookInformation?.title ?? "Unknown")WithId\(book.persistentBookInformation?.id ?? "Unknown")")
        bookThemesFetchedResultsController?.delegate = self
        
        try? bookThemesFetchedResultsController?.performFetch()
        themesTableView.reloadData()
    }
    
    func deinitFetchedResultsController() {
        bookThemesFetchedResultsController?.delegate = nil
        bookThemesFetchedResultsController = nil
        themesTableView.reloadData()
    }
    
    //MARK:- configure UI
    
    
    func configureUIWithBookInformation(from book: Book?) {
        
        titleLbl.text = book?.persistentBookInformation?.title ?? "Title unavailable"
        
        themePageControl.numberOfPages = bookThemesFetchedResultsController?.sections?[0].numberOfObjects ?? 0
    }
    
    func configureTapViewsWithGestureRecognizers() {
        bookInformationTapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewBookInformation)))
        notesTapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewNotes)))
        
        //configure scrolling for table view
        let tableViewGestureRecognizerSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(scrollToNextCellOfThemesTableView))
        tableViewGestureRecognizerSwipeUp.direction = .up
        themesTableView.addGestureRecognizer(tableViewGestureRecognizerSwipeUp)
        
        let tableViewGestureRecognizerSwipeDown = UISwipeGestureRecognizer(target: self, action: #selector(scrollToPreviousCellOfThemesTableView))
        tableViewGestureRecognizerSwipeDown.direction = .down
        themesTableView.addGestureRecognizer(tableViewGestureRecognizerSwipeDown)
        
    }
    
    //MARK:- UIViewController: viewDidLoad, viewWillAppear, viewWillDisappear
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTapViewsWithGestureRecognizers()
        themesTableView.delegate = self
        themesTableView.dataSource = self
        themesTableView.separatorStyle = .none
        themesTableView.isScrollEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initFetchedResultsController()
        configureUIWithBookInformation(from: book)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        switchToThemesTableView(atRow: 0)
        deinitFetchedResultsController()
    }
    
    //MARK:- IbActions and event handlers
    
    @objc func viewBookInformation() {
        performSegue(withIdentifier: "viewBookInformation", sender: book?.persistentBookInformation?.codableBookInformation)
    }
    
    @objc func viewNotes() {
        performSegue(withIdentifier: "viewNotes", sender: book)
    }
    
    @IBAction func onPageControlValueChange(_ sender: Any) {
        switchToThemesTableView(atRow: themePageControl.currentPage)
    }
    
    @IBAction func createNewTheme(_ sender: Any) {
        
        let failureClosure: (() -> ()) = {
            let failureAlertVC = UIAlertController(title: "Error", message: "Unable to create new theme.", preferredStyle: .alert)
            failureAlertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(failureAlertVC, animated: true, completion: nil)
        }
        
        let alertVC = UIAlertController(title: "Create new theme", message: "Enter the title of your new theme below...", preferredStyle: .alert)
        alertVC.addTextField { textfield in
            textfield.placeholder = "Enter theme here..."
        }
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let dataController = self.dataController, let alertTextfields = alertVC.textFields, alertTextfields.count > 0 {
                let newTheme = BookTheme(context: dataController.viewContext)
                newTheme.book = self.book
                newTheme.title = alertTextfields[0].text ?? "Untitled theme"
                
                if alertTextfields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                    newTheme.title = "Untitled theme"
                }
                
                newTheme.themeId = Int32(self.bookThemesFetchedResultsController?.fetchedObjects?.last?.themeId ?? -1)
                do {
                    try dataController.viewContext.save()
                } catch {
                    failureClosure()
                }
            } else {
                failureClosure()
            }
        }))
        
        present(alertVC, animated: true, completion: nil)
        
        
    }
    
    //MARK: preparing for segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let bookInformationVC = segue.destination as? ReadingListBookInformationViewController, segue.identifier == "viewBookInformation" {
            
            bookInformationVC.bookInfo = book?.persistentBookInformation?.codableBookInformation
            
        } else if let notesVC = segue.destination as? ReadingListBookNotesListViewController, segue.identifier == "viewNotes" {
            notesVC.book = book
            notesVC.dataController = dataController
        } else if let themeVC = segue.destination as? ReadingListBookNotesListViewController, segue.identifier == "viewNotesForTheme", let book = book, let bookTheme = sender as? BookTheme {
            themeVC.dataController = dataController
            themeVC.book = book
            themeVC.filteredBookTheme = bookTheme
        }
    }
}

extension ReadingListBookDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return bookThemesFetchedResultsController?.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookThemesFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "themeCellForBookDetails") as? ReadingListBookDetailsThemeCell, let theme = bookThemesFetchedResultsController?.object(at: indexPath) else { return UITableViewCell() }
        cell.themeLbl.text = bookThemesFetchedResultsController?.object(at: indexPath).title ?? "Untitled theme"
        cell.onThemeDetail_btnTapEventHandler = {
            self.performSegue(withIdentifier: "viewNotesForTheme", sender: theme)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let theme = bookThemesFetchedResultsController?.object(at: indexPath) else { return }
        self.performSegue(withIdentifier: "viewNotesForTheme", sender: theme)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "DELETE") { action, targetView, completionHandler in
            guard let objToDelete = self.bookThemesFetchedResultsController?.object(at: indexPath) else {
                completionHandler(false)
                return
            }
            
            let alertVC = UIAlertController(title: "Warning", message: "Are you sure you want to delete the theme \(objToDelete.title ?? "Untitled theme")? This action can't be undone. All notes on the book will also be deleted.", preferredStyle: .alert)
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
        
    @objc func switchToThemesTableView(atRow row: Int) {
        themePageControl.currentPage = row

        if row < (bookThemesFetchedResultsController?.sections?[0].numberOfObjects ?? 0) && row >= 0 {
            currentScrollingIndexPathForThemesTableViewIndexPath.row = row
            themesTableView.scrollToRow(at: currentScrollingIndexPathForThemesTableViewIndexPath, at: .none, animated: true)
        }
    }
    
    
    @objc func scrollToNextCellOfThemesTableView() {
        switchToThemesTableView(atRow: currentScrollingIndexPathForThemesTableViewIndexPath.row+1)
    }
    
    @objc func scrollToPreviousCellOfThemesTableView() {
        switchToThemesTableView(atRow: currentScrollingIndexPathForThemesTableViewIndexPath.row-1)
    }
    
}


extension ReadingListBookDetailsViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        themesTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        
        themesTableView.endUpdates()
        
        if let newRowToScrollTo = newRowToScrollTo {
            switchToThemesTableView(atRow: newRowToScrollTo.row)
            
        }
        
        newRowToScrollTo = nil
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        configureUIWithBookInformation(from: book)
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                themesTableView.insertRows(at: [newIndexPath], with: .automatic)
                configureUIWithBookInformation(from: book)
                newRowToScrollTo = newIndexPath
            }
        case .delete:
            if let indexPath = indexPath {
                themesTableView.deleteRows(at: [indexPath], with: .automatic)
            }
        case .update:
            if let indexPath = indexPath {
                themesTableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                themesTableView.moveRow(at: indexPath, to: newIndexPath)
            }
        default: break
        }
        
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            themesTableView.insertSections(indexSet, with: .fade)
        case .delete:
            themesTableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            break
        default: break
        }
    }
}
