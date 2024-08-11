//
//  Book+Extension.swift
//  BookReview
//
//  Created by Rohan Sinha on 8/9/21.
//

import Foundation

extension Book {
    var readingStatus: BookReadingStatus {
        get {
            return BookReadingStatus(rawValue: readingStatusInt) ?? .error
        }
        
        set {
            readingStatusInt = newValue.rawValue
        }
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        dateAdded = Date()
    }
    
    func configurePersistentInformation(from searchResult: BookInformation) {
        guard let managedObjectContext = managedObjectContext else { return }
        let bookInformation = PersistentBookInformation(context: managedObjectContext)
        title = searchResult.title
        bookInformation.title = searchResult.title
        bookInformation.subtitle = searchResult.subtitle
        bookInformation.ratingsCount = Int32(searchResult.ratingsCount ?? 0)
        bookInformation.publisher = searchResult.publisher
        bookInformation.publishedDate = searchResult.publishedDate
        bookInformation.printType = searchResult.printType
        bookInformation.pageCount = Int32(searchResult.pageCount ?? 0)
        bookInformation.maturityRating = searchResult.maturityRating
        bookInformation.isbn13 = searchResult.isbn13
        bookInformation.isbn10 = searchResult.isbn10
        bookInformation.imageLinks = searchResult.imageLinks?.thumbnail
        bookInformation.id = searchResult.id
        bookInformation.bookDescription = searchResult.bookDescription
        bookInformation.averageRating = searchResult.averageRating ?? 0.0
        bookInformation.authors = searchResult.authors?.joined(separator: ", ")
        persistentBookInformation = bookInformation
    }
}
