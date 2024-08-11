//
//  BookInformation.swift
//  BookReview
//
//  Created by Rohan Sinha on 7/21/21.
//

import Foundation

public class IndustryIdentifier: Codable {
    var type: String?
    var identifier: String?
    
    init(typeParam: String, identifierParam: String) {
        type = typeParam
        identifier = identifierParam
    }
    
}
public class ImageLinksForBook: Codable {
    var smallThumbnail: String?
    var thumbnail: String?
    
    enum ImageLinkTypes {
        case thumbnail
        case smallThumbnail
    }
    
    init(url: String?, type: ImageLinkTypes) {
        if type == .thumbnail {
            thumbnail = url
        } else if type == .smallThumbnail {
            smallThumbnail = url
        }
    }
    
}

public class BookInformation: Codable {
    
    var id: String?
    var title: String?
    var subtitle: String?
    var authors: [String]?
    var publisher: String?
    var publishedDate: String?
    var industryIdentifiers: [IndustryIdentifier]?
    var pageCount: Int?
    var printType: String?
    var averageRating: Double?
    var ratingsCount: Int?
    var maturityRating: String?
    var imageLinks: ImageLinksForBook?
    var bookDescription: String?
     
    var isbn10: String? {
        if let potentialIsbns = industryIdentifiers {
            let isbn10_filtered = potentialIsbns.filter { $0.type == "ISBN_10" }
            if isbn10_filtered.count == 1 && potentialIsbns[0].type == "ISBN_10" {
                return potentialIsbns[0].identifier
            }
        }
        
        return nil
    }
    
    var isbn13: String? {
        if let potentialIsbns = industryIdentifiers {
            let isbn13_filtered = potentialIsbns.filter { $0.type == "ISBN_13" }
            if isbn13_filtered.count == 1 && isbn13_filtered[0].type == "ISBN_13" {
                return isbn13_filtered[0].identifier
            }
        }
        
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case authors
        case publisher
        case publishedDate
        case industryIdentifiers
        case pageCount
        case printType
        case averageRating
        case ratingsCount
        case maturityRating
        case imageLinks
        case bookDescription = "description"
    }
    
    init(persistentBookInformation: PersistentBookInformation) {
        id = persistentBookInformation.id
        title = persistentBookInformation.title
        subtitle = persistentBookInformation.subtitle
        authors = persistentBookInformation.authors?.components(separatedBy: ", ")
        publisher = persistentBookInformation.publisher
        publishedDate = persistentBookInformation.publishedDate
        industryIdentifiers = []
        
        if let isbn10Val = persistentBookInformation.isbn10 {
            industryIdentifiers?.append(IndustryIdentifier(typeParam: "ISBN_10", identifierParam: isbn10Val))
        }
        
        if let isbn13Val = persistentBookInformation.isbn13 {
            industryIdentifiers?.append(IndustryIdentifier(typeParam: "ISBN_13", identifierParam: isbn13Val))
        }
        
        pageCount = Int(persistentBookInformation.pageCount)
        printType = persistentBookInformation.printType
        averageRating = persistentBookInformation.averageRating
        ratingsCount = Int(persistentBookInformation.ratingsCount)
        maturityRating = persistentBookInformation.maturityRating
        imageLinks = ImageLinksForBook(url: persistentBookInformation.imageLinks, type: .thumbnail)
        bookDescription = persistentBookInformation.bookDescription
        
    }
 
}
