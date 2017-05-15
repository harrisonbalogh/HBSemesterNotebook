//
//  TableTestViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/11/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class TableTestViewController: NSViewController, NSCollectionViewDataSource {
    
//    @IBOutlet weak var tableViewTester: NSTableView!
    @IBOutlet weak var collectionTestView: NSCollectionView!
    
    private var thisSemester: Semester! {
        didSet {
            lecturesToPopulate = thisSemester.courses!.count
            collectionTestView.reloadData()
        }
    }
    private var lecturesToPopulate = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionTestView.dataSource = self
        collectionTestView.maxNumberOfColumns = 1
        collectionTestView.minItemSize.height = 100
        
    }
    func initialize(withSemester semester: Semester) {
        self.thisSemester = semester
    }

    @IBAction func action_populate(_ sender: Any) {
        lecturesToPopulate += 1
        collectionTestView.reloadData()
    }
    
    // MARK: NSCollectionView Data Source Methods
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return lecturesToPopulate
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let item = collectionView.makeItem(withIdentifier: "HXCollectionViewItem", for: indexPath) as! HXCollectionViewItem
        
        return item
    }
}
