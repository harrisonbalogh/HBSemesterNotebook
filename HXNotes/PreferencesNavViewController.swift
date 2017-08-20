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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Have to set the color of the button text here... stupid NSButtons
        
//        var recoloredText = NSMutableAttributedString(attributedString: buttonGeneral.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,buttonGeneral.attributedTitle.length))
//        buttonGeneral.attributedTitle = recoloredText
//        
//        recoloredText = NSMutableAttributedString(attributedString: buttonEditor.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,buttonEditor.attributedTitle.length))
//        buttonEditor.attributedTitle = recoloredText
//        
//        recoloredText = NSMutableAttributedString(attributedString: buttonAlerts.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,buttonAlerts.attributedTitle.length))
//        buttonAlerts.attributedTitle = recoloredText
//        
//        recoloredText = NSMutableAttributedString(attributedString: buttonScheduler.attributedTitle)
//        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,buttonScheduler.attributedTitle.length))
//        buttonScheduler.attributedTitle = recoloredText
        
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
    
}



























