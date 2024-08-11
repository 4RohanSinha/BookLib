//
//  ReadingListViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/19/21.
//

import UIKit
import CoreData

class ReadingListViewController: CoreDataStackViewController {
    
    @IBOutlet weak var readingListTableView: UITableView!
    @IBOutlet weak var booksSearchView: UISearchBar!
    @IBOutlet weak var noResultsAvailableLbl: UILabel!
    
    var fetchedResultsController: NSFetchedResultsController<Book>?
    var cacheOfCovers = NSCache<NSNumber, UIImageCache>()
    
    func configureFetchedResultsController() {
        
        guard let dataController = dataController else { return }
        
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "dateAdded", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            alert(title: "Error", msg: "Unable to fetch books")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureFetchedResultsController()
        readingListTableView.reloadData()
        noResultsAvailableLbl.isHidden = true
        

        if booksSearchView.text != nil && booksSearchView.text != "" {
            performSearch(searchBar: booksSearchView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController?.delegate = nil
        fetchedResultsController = nil
        cacheOfCovers.removeAllObjects()
        noResultsAvailableLbl.isHidden = true
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        readingListTableView.dataSource = self
        readingListTableView.delegate = self
        readingListTableView.separatorStyle = .none
        
        booksSearchView.delegate = self
        
        let dismissSearchInputViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissSearchBar))
        dismissSearchInputViewGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissSearchInputViewGestureRecognizer)
        
    }
    
    func loadCoverImage(url: String, imageCacheObject: UIImageCache) {
        FetchImage.getImage(withUrl: HelperFunctions.convertHttpToHttps(httpUrl: url) ?? "") { imageData, error in

            if let imageData = imageData, let image = UIImage(data: imageData) {
                imageCacheObject.image = image
            }
            
            DispatchQueue.main.async {
                self.readingListTableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailVC = segue.destination as? ReadingListBookDetailsViewController, let book = sender as? Book, segue.identifier == "seeBookDetails" {
            detailVC.dataController = dataController
            detailVC.book = book
        }
    }
    

}

extension ReadingListViewController: UISearchBarDelegate {
    func performSearch(searchBar: UISearchBar) {
        
        guard let searchQuery = searchBar.text else { return }
        
        noResultsAvailableLbl.isHidden = true
        
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            fetchedResultsController?.fetchRequest.predicate = nil
            try? fetchedResultsController?.performFetch()
            readingListTableView.reloadData()
            return
        }
        
        let searchPredicateTitle: NSPredicate = NSPredicate(format: "persistentBookInformation.title LIKE[c] %@", "*\(searchQuery)*")

        let searchPredicateAuthor: NSPredicate = NSPredicate(format: "persistentBookInformation.authors != NIL AND persistentBookInformation.authors LIKE[c] %@", "*\(searchQuery)*")
        let searchPredicatePublisher: NSPredicate = NSPredicate(format: "persistentBookInformation.publisher != NIL AND persistentBookInformation.publisher LIKE[c] %@", "*\(searchQuery)*")
        let searchPredicateIsbn10: NSPredicate = NSPredicate(format: "persistentBookInformation.isbn10 != NIL AND persistentBookInformation.isbn10 LIKE[c] %@", "*\(searchQuery)*")
        let searchPredicateIsbn13: NSPredicate = NSPredicate(format: "persistentBookInformation.isbn13 != NIL AND persistentBookInformation.isbn13 LIKE[c] %@", "*\(searchQuery)*")

        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [searchPredicateTitle, searchPredicateAuthor, searchPredicatePublisher, searchPredicateIsbn10, searchPredicateIsbn13])
        fetchedResultsController?.fetchRequest.predicate = searchPredicate
        try? fetchedResultsController?.performFetch()
        
        readingListTableView.reloadData()
        
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            noResultsAvailableLbl.isHidden = false
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(searchBar: searchBar)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        performSearch(searchBar: searchBar)
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        fetchedResultsController?.fetchRequest.predicate = nil
        searchBar.resignFirstResponder()
    }
    
    @objc func dismissSearchBar() {
        booksSearchView.resignFirstResponder()
    }
}

extension ReadingListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return booksSearchView.isFirstResponder
    }
}

extension ReadingListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "readingListBookCell") as? ReadingListBookCell else { return UITableViewCell() }
        
        let book = fetchedResultsController?.object(at: indexPath)
        
        cell.selectionStyle = .none
        
        cell.bookView.coverView.image = nil
        cell.bookView.titleLbl.text = book?.persistentBookInformation?.title
        cell.bookView.authorLbl.text = book?.persistentBookInformation?.authors ?? "Unavailable"
        cell.bookView.publisherLbl.text = book?.persistentBookInformation?.publisher ??  "Unavailable"
        cell.bookView.isbn10Lbl.text = book?.persistentBookInformation?.isbn10 ?? "Unavailable"
        cell.bookView.isbn13Lbl.text = book?.persistentBookInformation?.isbn13 ?? "Unavailable"
                
        if let pageCount = book?.persistentBookInformation?.pageCount, pageCount > 0 {
            cell.bookView.pageCountLbl.text = String(describing: pageCount)
        } else {
            cell.bookView.pageCountLbl.text = "Unavailable"
        }
        
        if let cachedImageObject = cacheOfCovers.object(forKey: NSNumber(value: indexPath.row)), cachedImageObject.downloaded {
            cell.bookView.configureCoverImage(image: cachedImageObject.image)
        } else if let imageLink = book?.persistentBookInformation?.imageLinks {
            let imageCacheObject = UIImageCache()
            imageCacheObject.downloaded = true
            cacheOfCovers.setObject(imageCacheObject, forKey: NSNumber(value: indexPath.row))
            loadCoverImage(url: imageLink, imageCacheObject: imageCacheObject)
            cell.bookView.loadingCover = true
        } else {
            let imageCacheObject = UIImageCache()
            imageCacheObject.downloaded = false
            cacheOfCovers.setObject(imageCacheObject, forKey: NSNumber(value: indexPath.row))
            cell.bookView.configureCoverImage(image: nil)
        }
        
        cell.bookView.backgroundColor = .systemIndigo
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let book = fetchedResultsController?.object(at: indexPath) {
            performSegue(withIdentifier: "seeBookDetails", sender: book)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "DELETE") { action, targetView, completionHandler in
            guard let objToDelete = self.fetchedResultsController?.object(at: indexPath) else {
                completionHandler(false)
                return
            }
            
            let alertVC = UIAlertController(title: "Warning", message: "Are you sure you want to delete the book \(objToDelete.persistentBookInformation?.title ?? "Unknown title")? This action can't be undone. All notes on the book will also be deleted.", preferredStyle: .alert)
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

extension ReadingListViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        readingListTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        readingListTableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                readingListTableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                readingListTableView.moveRow(at: indexPath, to: newIndexPath)
            }
        case .update:
            if let indexPath = indexPath {
                readingListTableView.reloadRows(at: [indexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                readingListTableView.deleteRows(at: [indexPath], with: .fade)
            }
        default: break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            readingListTableView.insertSections(indexSet, with: .fade)
        case .delete:
            readingListTableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            break
        default: break
        }
    }
}
