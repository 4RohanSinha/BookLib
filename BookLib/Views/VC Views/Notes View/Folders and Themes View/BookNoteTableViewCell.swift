//
//  BookNoteTableViewCell.swift
//  BookReview
//
//  Created by Rohan Sinha on 9/18/21.
//

import UIKit

class BookNoteTableViewCell: UITableViewCell {

    @IBOutlet weak var themesCollectionView: UICollectionView!
    
    private var _themesCollectionViewDelegates: BookNoteThemesTableCollectionViewDelegate?
    
    var onThemeCellTapHandler: ((IndexPath) -> ())? {
        get {
            return _themesCollectionViewDelegates?.onThemeTapHandler
        } set {
            _themesCollectionViewDelegates?.onThemeTapHandler = newValue
        }
    }
    
    var themesCollectionViewDelegates: BookNoteThemesTableCollectionViewDelegate? {
        get {
            return _themesCollectionViewDelegates
        }
        set {
            _themesCollectionViewDelegates = newValue
            themesCollectionView.dataSource = newValue
            themesCollectionView.delegate = newValue
            themesCollectionView.reloadData()
        }
    }

}
