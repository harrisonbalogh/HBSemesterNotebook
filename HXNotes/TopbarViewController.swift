//
//  TopbarViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class TopbarViewController: NSViewController {
    
    var masterViewController: MasterViewController!
    
    var findViewController: HXFindViewController!
    var exportViewController: HXExportViewController!
    var replaceViewController: HXFindReplaceViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        findViewController = HXFindViewController(nibName: "HXFindView", bundle: nil)
        self.addChildViewController(findViewController)
        exportViewController = HXExportViewController(nibName: "HXExportView", bundle: nil)
        self.addChildViewController(exportViewController)
        replaceViewController = HXFindReplaceViewController(nibName: "HXFindReplaceView", bundle: nil)
        self.addChildViewController(replaceViewController)
    }
}
