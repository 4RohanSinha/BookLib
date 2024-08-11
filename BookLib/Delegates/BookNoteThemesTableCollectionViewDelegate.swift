//
//  BookNoteThemesTableCollectionViewDelegate.swift
//  BookReview
//
//  Created by Rohan Sinha on 9/18/21.
//

import UIKit

class BookNoteThemesTableCollectionViewDelegate: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var themes: [BookTheme] = []
    var cellIdentifier: String?
    var onThemeTapHandler: ((IndexPath) -> ())?
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cellIdentifier = cellIdentifier, let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? BookNoteThemeCollectionViewCell {
            cell.themeLbl.text = themes[indexPath.row].title
            return cell
        }
        
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onThemeTapHandler?(indexPath)
    }
}
