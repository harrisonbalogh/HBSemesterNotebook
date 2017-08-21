//
//  PreferencesNavViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class PreferencesNavViewController: NSViewController {
    
    var preferencesVC: PreferencesViewController!

    @IBOutlet weak var buttonGeneral: NSButton!
    @IBOutlet weak var buttonEditor: NSButton!
    @IBOutlet weak var buttonAlerts: NSButton!
    @IBOutlet weak var buttonScheduler: NSButton!
    @IBOutlet weak var buttonSidebar: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func action_general(_ sender: NSButton) {
        let y = preferencesVC.labelGeneral.superview!.frame.height - preferencesVC.labelGeneral.frame.origin.y - preferencesVC.labelGeneral.frame.height
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_editor(_ sender: NSButton) {
        let y = preferencesVC.labelEditor.superview!.frame.height - preferencesVC.labelEditor.frame.origin.y - preferencesVC.labelEditor.frame.height
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_alerts(_ sender: NSButton) {
        let y = preferencesVC.labelAlerts.superview!.frame.height - preferencesVC.labelAlerts.frame.origin.y - preferencesVC.labelAlerts.frame.height
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_scheduler(_ sender: NSButton) {
        let y = preferencesVC.labelScheduler.superview!.frame.height - preferencesVC.labelScheduler.frame.origin.y - preferencesVC.labelScheduler.frame.height
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_sidebar(_ sender: NSButton) {
        let y = preferencesVC.labelSidebar.superview!.frame.height - preferencesVC.labelSidebar.frame.origin.y - preferencesVC.labelSidebar.frame.height
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    
}



























