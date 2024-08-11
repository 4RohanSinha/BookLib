//
//  SearchBooksViewController.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/24/21.
//

import UIKit
import CoreData

class SearchBooksViewController: CoreDataStackViewController {

    @IBOutlet weak var basicQuerySearchInput: UISearchBar!
    @IBOutlet weak var searchAdvancedView: AdvancedSearchView!
    @IBOutlet weak var searchResultsTableView: UITableView!
    @IBOutlet weak var searchResultsLoadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var searchResultsLoadingStackView: UIStackView!
    @IBOutlet weak var welcomeMessage: UILabel!
    @IBOutlet weak var noResultsLbl: UILabel!
    
    var searchQuery: SearchQuery = SearchQuery()
    var searchTask: URLSessionTask?
    var searchResults: [SearchResultBookContainer] = []
    
    var booksFetchedResultsController: NSFetchedResultsController<Book>?
    var reloadResults: Bool?
    
    var showsBarcodeResults: Bool = false
    
    var errorShown: Bool = false
    
    func configureFetchedResultsController() {
        
        guard let dataController = dataController else { return }
        
        let booksFetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        booksFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: true)]
        
        booksFetchedResultsController = NSFetchedResultsController(fetchRequest: booksFetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "booksForSearchViewController")
        booksFetchedResultsController?.delegate = self
        
        
        try? booksFetchedResultsController?.performFetch()
    }
    
    func deinitFetchedResultsController() {
        booksFetchedResultsController?.delegate = nil
        booksFetchedResultsController = nil
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        if !showsBarcodeResults && searchQuery.isEmpty {
            if let storedSearchQueryData = UserDefaults.standard.data(forKey: "searchQuery") {
                do {
                    let storedSearchQuery = try JSONDecoder().decode(SearchQuery.self, from: storedSearchQueryData)
                    searchQuery = storedSearchQuery
                    basicQuerySearchInput.text = searchQuery.basicQuery
                } catch {
                    alert(title: "Error", msg: "Unable to restore search query from previous session.")
                }
            }
        }
        
        let advancedSearchViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(reconfigureAdvancedSearch))
        
        searchAdvancedView.addGestureRecognizer(advancedSearchViewGestureRecognizer)
        
        let dismissSearchInputViewGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissSearchBar))
        dismissSearchInputViewGestureRecognizer.delegate = self
        view.addGestureRecognizer(dismissSearchInputViewGestureRecognizer)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchResultsTableView.reloadData()
        
        configureFetchedResultsController()
        
        noResultsLbl.isHidden = true
        
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.separatorStyle = .none
        
        basicQuerySearchInput.delegate = self

        configureAdvancedSearchView()
        
        if reloadResults == true && !searchQuery.isEmpty {
            getSearchResults()
        } else if !searchQuery.isEmpty && reloadResults == nil {
            getSearchResults()
        }
        
        if searchQuery.isEmpty && searchResults.isEmpty {
            welcomeMessage.isHidden = false
        }
        
        reloadResults = nil
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deinitFetchedResultsController()
        errorShown = false
    }
    
    func configureAdvancedSearchView() {
        searchAdvancedView.configureLabel(withQuery: searchQuery)
    }
    
    func configureViewForLoadingResults(complete: Bool) {
        searchResultsLoadingStackView.isHidden = complete
        searchResultsTableView.isHidden = !complete
        
        if complete {
            searchResultsLoadingActivityIndicator.stopAnimating()
        } else {
            searchResultsLoadingActivityIndicator.startAnimating()
        }
        
    }
    
    func getSearchResults() {
        guard !searchQuery.isEmpty else { return }
        searchResults.removeAll()
        
        noResultsLbl.isHidden = true
        welcomeMessage.isHidden = true
        configureViewForLoadingResults(complete: false)
        
        
        if searchTask?.progress.isCancellable == true {
            searchTask?.cancel()
        }
        
        
        //make network request
        searchTask = GoogleBooksAPIClient.searchBooks(withQuery: searchQuery) { (responseObj, error) in
            
            
            DispatchQueue.main.async {
                self.configureViewForLoadingResults(complete: true)
                
                //error code for lack of network connectivity = -1009
                //check if reason for network failure is a lack of connectivity
                //documentation - https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes/nsurlerrornotconnectedtointernet
                if let error = error as NSError?, error.code == -1009 && !self.errorShown {
                    
                    self.alert(title: "Error", msg: "Unable to connect to network servers")
                    self.errorShown = true
                } else if responseObj != nil {
                    self.errorShown = false
                }

                if let books = responseObj?.items {
                    for i in books {
                        i.volumeInfo.id = i.id
                    }
                    self.searchResults = books
                }
                
                self.searchResultsTableView.reloadData()
                
                if self.searchTask?.progress.isCancelled == false {
                    if self.searchResults.count == 0 {
                        self.noResultsLbl.isHidden = false
                    } else {
                        self.noResultsLbl.isHidden = true
                    }
                }
                
            }
        }
        
    }
    
    func bookAlreadyExists(bookInfo: BookInformation) -> Bool {
        
        if let readingList = booksFetchedResultsController?.fetchedObjects {
            for book_i in readingList {
                if book_i.persistentBookInformation?.id == bookInfo.id {
                    return true
                }
            }
        }
        
        return false
    }

    
    //MARK: - IbActions and event handlers
    @objc func reconfigureAdvancedSearch() {
        searchTask?.cancel()
        performSegue(withIdentifier: "configureAdvancedSearchQuery", sender: searchQuery)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let configureAdvancedSearchVC = segue.destination as? ConfigureAdvancedSearchViewController, let searchQuery = sender as? SearchQuery, segue.identifier == "configureAdvancedSearchQuery" {
            configureAdvancedSearchVC.searchQuery = searchQuery
            reloadResults = true
        } else if let bookInfoVC = segue.destination as? ReadingListBookInformationViewController, let bookIndexPath = sender as? IndexPath, segue.identifier == "seeInformationAboutBookFromSearchResults" {
            bookInfoVC.bookInfo = searchResults[bookIndexPath.row].volumeInfo
            bookInfoVC.onAddBtnTapClosure = {
                self.addBookToReadingList(indexPath: bookIndexPath)
            }
            bookInfoVC.bookIsAdded = bookAlreadyExists(bookInfo: searchResults[bookIndexPath.row].volumeInfo)
            reloadResults = false
        }
    }
    
}

extension SearchBooksViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return basicQuerySearchInput.isFirstResponder
    }
}

extension SearchBooksViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchQuery.basicQuery = basicQuerySearchInput.text
        
        if let encodedSearchQuery = try? JSONEncoder().encode(searchQuery), !searchQuery.isEmpty && !showsBarcodeResults {
            UserDefaults.standard.set(encodedSearchQuery, forKey: "searchQuery")
        }
        
        if basicQuerySearchInput.text?.trimmingCharacters(in: .whitespaces) != "" {
            getSearchResults()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if searchResults.count == 0 {
            getSearchResults()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    @objc func dismissSearchBar() {
        basicQuerySearchInput.resignFirstResponder()
    }
}

extension SearchBooksViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell") as? SearchResultCell else { return UITableViewCell() }
        
        if indexPath.row < searchResults.count {
            cell.configureView(withBookInformation: searchResults[indexPath.row].volumeInfo)
            
            cell.infoBookHandler = {
                self.performSegue(withIdentifier: "seeInformationAboutBookFromSearchResults", sender: indexPath)
            }
            
            if bookAlreadyExists(bookInfo: searchResults[indexPath.row].volumeInfo) {
                cell.addButton.isEnabled = false
                SearchResultCellButtonType.added.configureAddButton(cell.addButton)
            } else {
                cell.addButton.isEnabled = true
                SearchResultCellButtonType.new.configureAddButton(cell.addButton)
                cell.addBookHandler = {
                    self.addBookToReadingList(indexPath: indexPath)
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "seeInformationAboutBookFromSearchResults", sender: indexPath)
    }
    
}


extension SearchBooksViewController {
    func addBookToReadingList(indexPath: IndexPath) { 
        if let viewContext = dataController?.viewContext {
            let newBookObject = Book(context: viewContext)
            newBookObject.configurePersistentInformation(from: searchResults[indexPath.row].volumeInfo)
            newBookObject.pagesRead = 0
            try? viewContext.save()
        }
    }
}


extension SearchBooksViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    }
}

