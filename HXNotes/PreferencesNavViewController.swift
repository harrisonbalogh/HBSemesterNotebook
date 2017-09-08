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
    
    @IBAction func action_done(_ sender: NSButton) {
        preferencesVC.masterVC.action_preferencesToggle(sender)
    }
    @IBAction func action_cancel(_ sender: NSButton) {
        preferencesVC.cancel = true
        preferencesVC.masterVC.action_preferencesToggle(sender)
    }
    
    @IBAction func action_general(_ sender: NSButton) {
        let y = preferencesVC.labelGeneral.superview!.superview!.frame.height - preferencesVC.labelGeneral.superview!.frame.origin.y - preferencesVC.labelGeneral.superview!.frame.height
        
        preferencesVC.clipView.enclosingScrollView!.flashScrollers()
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_editor(_ sender: NSButton) {
        let y = preferencesVC.labelEditor.superview!.superview!.frame.height - preferencesVC.labelEditor.superview!.frame.origin.y - preferencesVC.labelEditor.superview!.frame.height
        
        preferencesVC.clipView.enclosingScrollView!.flashScrollers()
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_alerts(_ sender: NSButton) {
        let y = preferencesVC.labelAlerts.superview!.superview!.frame.height - preferencesVC.labelAlerts.superview!.frame.origin.y - preferencesVC.labelAlerts.superview!.frame.height
        
        preferencesVC.clipView.enclosingScrollView!.flashScrollers()
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_scheduler(_ sender: NSButton) {
        let y = preferencesVC.labelScheduler.superview!.superview!.frame.height - preferencesVC.labelScheduler.superview!.frame.origin.y - preferencesVC.labelScheduler.superview!.frame.height
        
        preferencesVC.clipView.enclosingScrollView!.flashScrollers()
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_sidebar(_ sender: NSButton) {
        let y = preferencesVC.labelSidebar.superview!.superview!.frame.height - preferencesVC.labelSidebar.superview!.frame.origin.y - preferencesVC.labelSidebar.superview!.frame.height
        
        preferencesVC.clipView.enclosingScrollView!.flashScrollers()
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        preferencesVC.clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: y))
        NSAnimationContext.endGrouping()
    }
    
}



























