//
//  PreferencesViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func action_closePreferences(_ sender: NSButton) {
        let appDelegate = NSApp.delegate as! AppDelegate
        appDelegate.closeModal()
    }
}
